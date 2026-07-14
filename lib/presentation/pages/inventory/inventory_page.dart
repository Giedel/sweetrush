import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sweetrush/presentation/pages/inventory/add_product_page.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/ingredient.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/inventory/inventory_event.dart';
import '../../blocs/inventory/inventory_state.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final List<String> _categories = ['All', 'Dairy', 'Syrups', 'Toppings', 'Base'];

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(LoadInventory());
  }

  // DIALOG 1: Direct Entry Addition (Unchanged from original structure)
  void _showAddIngredientForm(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    String selectedCategory = 'Dairy';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Stock Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ingredient Name')),
                TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock Quantity')),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g., ml, g, pcs)')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: _categories.where((c) => c != 'All').map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) { if (value != null) selectedCategory = value; },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newIngredient = Ingredient(
                  id: const Uuid().v4(), 
                  name: nameController.text,
                  currentStock: double.tryParse(stockController.text) ?? 0.0,
                  unit: unitController.text,
                  category: selectedCategory,
                );
                context.read<InventoryBloc>().add(AddNewIngredient(newIngredient));
                Navigator.pop(dialogContext);
              },
              child: const Text('Save Stock'),
            ),
          ],
        );
      },
    );
  }

  // NEW DIALOG 2: Manage Existing Stock Levels
  void _showManageStockSheet(BuildContext context, Ingredient item) {
    final amountController = TextEditingController();
    bool isOverrideMode = false; // default to adjustment increment mode

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, setStateState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Stock: ${item.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Current baseline register: ${item.currentStock} ${item.unit}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Add Received'), icon: Icon(Icons.add_business)),
                      ButtonSegment(value: true, label: Text('Override Total'), icon: Icon(Icons.edit_note)),
                    ],
                    selected: {isOverrideMode},
                    onSelectionChanged: (val) => setStateState(() => isOverrideMode = val.first),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isOverrideMode ? 'Set Absolute Total' : 'Quantity to Add / Restock',
                      border: const OutlineInputBorder(),
                      suffixText: item.unit,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(amountController.text) ?? 0.0;
                        if (val == 0 && !isOverrideMode) return;

                        context.read<InventoryBloc>().add(UpdateIngredientStock(
                          ingredientId: item.id,
                          quantityChange: val,
                          isOverride: isOverrideMode,
                        ));

                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('CONFIRM QUANTITY ADJUSTMENT'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fastfood_outlined),
            tooltip: 'Add Menu Product',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage())),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add Raw Stock',
            onPressed: () => _showAddIngredientForm(context),
          )
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InventoryError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          if (state is InventoryLoaded) {
            final ingredients = state.filteredIngredients;
            
            return Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: state.selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              context.read<InventoryBloc>().add(FilterInventoryCategory(category));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ingredients.isEmpty 
                    ? const Center(child: Text("No items in this category."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: ingredients.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = ingredients[index];
                          // Simple dynamic visual validation constraints for low stock thresholds
                          final isLowStock = item.currentStock < 500; 

                          return ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Category: ${item.category}'),
                            // Tapping an item opens the sheet to update its stock
                            onTap: () => _showManageStockSheet(context, item),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.currentStock} ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isLowStock ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isLowStock) 
                                      const Text('Low Stock', style: TextStyle(color: Colors.red, fontSize: 12))
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}