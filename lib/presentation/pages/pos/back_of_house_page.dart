import 'package:flutter/material.dart';

import '../../../data/repositories/firebase_inventory_repository.dart';
import '../../../data/repositories/firebase_kitchen_repository.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/entities/kitchen_ticket.dart';
import '../../../domain/entities/recipe_step.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/repositories/kitchen_repository.dart';

class BackOfHousePage extends StatefulWidget {
  final KitchenRepository kitchenRepository;
  final InventoryRepository inventoryRepository;

  const BackOfHousePage({
    super.key,
    KitchenRepository? kitchenRepository,
    InventoryRepository? inventoryRepository,
  })  : kitchenRepository = kitchenRepository ?? const _DefaultKitchenRepository(),
        inventoryRepository = inventoryRepository ?? const _DefaultInventoryRepository();

  @override
  State<BackOfHousePage> createState() => _BackOfHousePageState();
}

class _BackOfHousePageState extends State<BackOfHousePage> {
  String? _expandedOrderId;
  int _selectedItemIndex = 0;
  final Map<int, Ingredient> _placedIngredientsByStep = {};
  int? _warningStep;
  String? _warningMessage;
  final Set<String> _completingOrderIds = {};

  bool _ingredientMatchesStep(Ingredient ingredient, RecipeStep step) {
    if (step.ingredientId.isNotEmpty) {
      return step.ingredientId == ingredient.id;
    }
    return step.ingredientName.trim().toLowerCase() ==
        ingredient.name.trim().toLowerCase();
  }

  void _selectOrder(KitchenTicket ticket) {
    setState(() {
      if (_expandedOrderId == ticket.id) {
        _expandedOrderId = null;
      } else {
        _expandedOrderId = ticket.id;
        _selectedItemIndex = 0;
        _placedIngredientsByStep.clear();
        _warningStep = null;
        _warningMessage = null;
      }
    });
  }

  void _selectOrderItem(int index) {
    setState(() {
      _selectedItemIndex = index;
      _placedIngredientsByStep.clear();
      _warningStep = null;
      _warningMessage = null;
    });
  }

  int? _nextExpectedStepOrder(List<RecipeStep> steps) {
    final sortedSteps = [...steps]..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
    for (final step in sortedSteps) {
      final placed = _placedIngredientsByStep[step.stepOrder];
      if (placed == null || !_ingredientMatchesStep(placed, step)) {
        return step.stepOrder;
      }
    }
    return null;
  }

  Future<void> _tryCompleteOrder(
    BuildContext context,
    KitchenTicket ticket,
    KitchenTicketItem item,
  ) async {
    if (item.recipeSequence.isEmpty) return;

    final allCorrect = item.recipeSequence.every((step) {
      final placedIngredient = _placedIngredientsByStep[step.stepOrder];
      if (placedIngredient == null) return false;
      return _ingredientMatchesStep(placedIngredient, step);
    });

    if (!allCorrect || _completingOrderIds.contains(ticket.id)) return;

    _completingOrderIds.add(ticket.id);

    try {
      await widget.kitchenRepository.completeOrder(ticket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket #${ticket.id.substring(0, 5).toUpperCase()} completed.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      setState(() {
        _expandedOrderId = null;
        _selectedItemIndex = 0;
        _placedIngredientsByStep.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete ticket: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      _completingOrderIds.remove(ticket.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<KitchenTicket>>(
      stream: widget.kitchenRepository.watchPendingOrders(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Center(child: Text('Error: ${orderSnapshot.error}'));
        }
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = orderSnapshot.data ?? const <KitchenTicket>[];
        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'Kitchen Queue is Empty ☕',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return StreamBuilder<List<Ingredient>>(
          stream: widget.inventoryRepository.getInventoryStream(),
          builder: (context, inventorySnapshot) {
            final ingredients = inventorySnapshot.data ?? const <Ingredient>[];
            final bool isInventoryLoading =
                inventorySnapshot.connectionState == ConnectionState.waiting;

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 700) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: _expandedOrderId == null ? 1.5 : 0.7,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final ticket = orders[index];
                    final isExpanded = _expandedOrderId == ticket.id;

                    return _KitchenTicketCard(
                      ticket: ticket,
                      ingredients: ingredients,
                      inventoryLoading: isInventoryLoading,
                      isExpanded: isExpanded,
                      selectedItemIndex: _selectedItemIndex,
                      placedIngredientsByStep: _placedIngredientsByStep,
                      warningStep: _warningStep,
                      warningMessage: _warningMessage,
                      onTap: () => _selectOrder(ticket),
                      onItemSelected: _selectOrderItem,
                      onIngredientDropped: (ingredient, step) async {
                        if (!isExpanded || ticket.items.isEmpty) return;

                        final selectedItem = ticket.items[
                            _selectedItemIndex.clamp(0, ticket.items.length - 1).toInt()];
                        final nextStepOrder =
                            _nextExpectedStepOrder(selectedItem.recipeSequence);

                        if (nextStepOrder != null &&
                            step.stepOrder != nextStepOrder) {
                          setState(() {
                            _warningStep = step.stepOrder;
                            _warningMessage =
                                'Wrong sequence: complete Step $nextStepOrder before Step ${step.stepOrder}.';
                          });
                          return;
                        }

                        final isMatch = _ingredientMatchesStep(ingredient, step);
                        if (!isMatch) {
                          setState(() {
                            _warningStep = step.stepOrder;
                            _warningMessage =
                                '${ingredient.name} does not match Step ${step.stepOrder} (${step.ingredientName}).';
                          });
                          return;
                        }

                        setState(() {
                          _placedIngredientsByStep[step.stepOrder] = ingredient;
                          _warningStep = null;
                          _warningMessage = null;
                        });

                        await _tryCompleteOrder(context, ticket, selectedItem);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _KitchenTicketCard extends StatelessWidget {
  final KitchenTicket ticket;
  final List<Ingredient> ingredients;
  final bool inventoryLoading;
  final bool isExpanded;
  final int selectedItemIndex;
  final Map<int, Ingredient> placedIngredientsByStep;
  final int? warningStep;
  final String? warningMessage;
  final VoidCallback onTap;
  final ValueChanged<int> onItemSelected;
  final Future<void> Function(Ingredient ingredient, RecipeStep step)
      onIngredientDropped;

  const _KitchenTicketCard({
    required this.ticket,
    required this.ingredients,
    required this.inventoryLoading,
    required this.isExpanded,
    required this.selectedItemIndex,
    required this.placedIngredientsByStep,
    required this.warningStep,
    required this.warningMessage,
    required this.onTap,
    required this.onItemSelected,
    required this.onIngredientDropped,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = ticket.items.length;
    final title = 'Ticket #${ticket.id.substring(0, 5).toUpperCase()}';
    final selectedItem = ticket.items.isEmpty
        ? null
        : ticket.items[
            selectedItemIndex.clamp(0, ticket.items.length - 1).toInt()
          ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isExpanded ? 16 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$itemCount item(s) pending',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (ticket.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Created ${TimeOfDay.fromDateTime(ticket.timestamp!).format(context)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              if (!isExpanded) const Spacer(),
              if (isExpanded && selectedItem != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Select drink/product',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(ticket.items.length, (index) {
                    final orderItem = ticket.items[index];
                    return ChoiceChip(
                      label: Text(orderItem.name),
                      selected: index == selectedItemIndex,
                      onSelected: (_) => onItemSelected(index),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '${selectedItem.name} (${selectedItem.selectedSize}) • ${selectedItem.sweetnessLevel}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (warningMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      warningMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _KitchenWorkspace(
                    steps: selectedItem.recipeSequence,
                    ingredients: ingredients,
                    inventoryLoading: inventoryLoading,
                    placedIngredientsByStep: placedIngredientsByStep,
                    warningStep: warningStep,
                    onIngredientDropped: onIngredientDropped,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenWorkspace extends StatelessWidget {
  final List<RecipeStep> steps;
  final List<Ingredient> ingredients;
  final bool inventoryLoading;
  final Map<int, Ingredient> placedIngredientsByStep;
  final int? warningStep;
  final Future<void> Function(Ingredient ingredient, RecipeStep step)
      onIngredientDropped;

  const _KitchenWorkspace({
    required this.steps,
    required this.ingredients,
    required this.inventoryLoading,
    required this.placedIngredientsByStep,
    required this.warningStep,
    required this.onIngredientDropped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 520;
        final poolPanel = _buildIngredientPool(context);
        final targetPanel = _buildTargetSlots(context);

        if (isWide) {
          return Row(
            children: [
              Expanded(child: poolPanel),
              const SizedBox(width: 12),
              Expanded(child: targetPanel),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: poolPanel),
            const SizedBox(height: 12),
            Expanded(child: targetPanel),
          ],
        );
      },
    );
  }

  Widget _buildIngredientPool(BuildContext context) {
    if (inventoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredient Pool',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients.map((ingredient) {
                  return Draggable<Ingredient>(
                    data: ingredient,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _IngredientChip(
                        ingredient: ingredient,
                        isDragging: true,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _IngredientChip(ingredient: ingredient),
                    ),
                    child: _IngredientChip(ingredient: ingredient),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSlots(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipe Target Zone',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (steps.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No recipe steps found for this product.'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final placed = placedIngredientsByStep[step.stepOrder];
                  final bool warned = warningStep == step.stepOrder;
                  final bool isCorrect = placed != null;

                  return DragTarget<Ingredient>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) {
                      onIngredientDropped(details.data, step);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final bool isHovering = candidateData.isNotEmpty;
                      Color borderColor = Colors.grey.shade400;

                      if (warned) {
                        borderColor = Colors.red.shade500;
                      } else if (isCorrect) {
                        borderColor = Colors.green.shade600;
                      } else if (isHovering) {
                        borderColor = Theme.of(context).colorScheme.primary;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 1.6),
                          color: warned
                              ? Colors.red.shade50
                              : isCorrect
                                  ? Colors.green.shade50
                                  : Colors.white,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blueGrey.shade200,
                              child: Text(
                                '${step.stepOrder}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.ingredientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${step.quantityRequired.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (placed != null)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(placed.name),
                                avatar: const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final Ingredient ingredient;
  final bool isDragging;

  const _IngredientChip({
    required this.ingredient,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${ingredient.name} (${ingredient.currentStock.toStringAsFixed(0)} ${ingredient.unit})',
      ),
      backgroundColor: isDragging ? Colors.white : Colors.orange.shade50,
      side: BorderSide(color: Colors.orange.shade200),
      avatar: const Icon(Icons.local_cafe, size: 16),
    );
  }
}

class _DefaultKitchenRepository implements KitchenRepository {
  const _DefaultKitchenRepository();

  @override
  Future<void> completeOrder(String orderId) {
    return FirebaseKitchenRepository().completeOrder(orderId);
  }

  @override
  Stream<List<KitchenTicket>> watchPendingOrders() {
    return FirebaseKitchenRepository().watchPendingOrders();
  }
}

class _DefaultInventoryRepository implements InventoryRepository {
  const _DefaultInventoryRepository();

  @override
  Future<void> addIngredient(Ingredient ingredient) {
    return FirebaseInventoryRepository().addIngredient(ingredient);
  }

  @override
  Stream<List<Ingredient>> getInventoryStream() {
    return FirebaseInventoryRepository().getInventoryStream();
  }

  @override
  Future<void> updateIngredientStock({
    required String ingredientId,
    required double quantityChange,
    required bool isOverride,
  }) {
    return FirebaseInventoryRepository().updateIngredientStock(
      ingredientId: ingredientId,
      quantityChange: quantityChange,
      isOverride: isOverride,
    );
  }
}