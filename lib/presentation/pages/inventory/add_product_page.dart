import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/ingredient.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/recipe_step.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/inventory/inventory_state.dart';
import '../../../data/repositories/firebase_product_repository.dart';
import '../../../data/models/product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  final Map<String, TextEditingController> _sizeControllers = {
    'Small': TextEditingController(text: '0.0'),
    'Regular': TextEditingController(text: '0.0'),
    'Large': TextEditingController(text: '0.0'),
  };
  
  Uint8List? _webImage;
  String? _pickedFileName;
  bool _isSaving = false;
  String _selectedCategory = 'Cakes';

  final List<RecipeStep> _recipeSteps = [];
  final _productRepository = FirebaseProductRepository();
  late final Stream<InventoryState> _inventoryStateStream;

  @override
  void initState() {
    super.initState();
    _inventoryStateStream = context.read<InventoryBloc>().stream;
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _sizeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
        _pickedFileName = image.name;
      });
    }
  }

  void _addRecipeStep(List<Ingredient> availableIngredients) {
    if (availableIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No base ingredients available in stock registers!')),
      );
      return;
    }
    
    setState(() {
      int nextOrder = _recipeSteps.length + 1;
      _recipeSteps.add(RecipeStep(
        stepOrder: nextOrder,
        ingredientId: availableIngredients.first.id,
        ingredientName: availableIngredients.first.name,
        quantityRequired: 10.0,
      ));
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _webImage == null || _recipeSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image, fill details, and append your recipe steps!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String secureUrl = await _productRepository.uploadImage(_webImage!, _pickedFileName!);

      final Map<String, double> parsedSizePrices = {};
      _sizeControllers.forEach((size, controller) {
        parsedSizePrices[size] = double.tryParse(controller.text) ?? 0.0;
      });

      final double fallbackBasePrice = parsedSizePrices['Regular'] ?? parsedSizePrices.values.first;

      final targetProduct = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        price: fallbackBasePrice,
        sizePrices: parsedSizePrices,
        imageUrl: secureUrl,
        category: _selectedCategory,
        recipeSequence: _recipeSteps,
      );

      await _productRepository.addProduct(targetProduct);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added with variations successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Menu Product'),
        // CLEAN UP: Moved Save action out of the scroll layout and up to the AppBar
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 28),
                  tooltip: 'Save Menu Product',
                  onPressed: _saveProduct,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<InventoryState>(
        stream: _inventoryStateStream,
        initialData: context.read<InventoryBloc>().state,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load inventory: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final state = snapshot.data;

          if (state is InventoryError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is! InventoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final ingredients = state.allIngredients;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name (e.g., Mango Sweet Frappe)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Menu Category', border: OutlineInputBorder()),
                  items: ['Cakes', 'Pastries', 'Drinks', 'Custom Blends'].map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? 'Cakes'),
                ),
                const SizedBox(height: 24),

                Text('Size & Price Configuration (PHP)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                Row(
                  children: _sizeControllers.entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: entry.key,
                            border: const OutlineInputBorder(),
                            prefixText: '₱',
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _webImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(_webImage!, fit: BoxFit.cover))
                        : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 40), SizedBox(height: 8), Text('Upload Image')])),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Base Recipe Mix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _addRecipeStep(ingredients),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Ingredient'),
                    )
                  ],
                ),
                const Divider(),

                ...List.generate(_recipeSteps.length, (idx) {
                  final step = _recipeSteps[idx];

                  return Card(
                    key: ValueKey('recipe_step_${step.stepOrder}_${step.ingredientId}'),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(child: Text('${step.stepOrder}')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: step.ingredientId,
                                isExpanded: true,
                                items: ingredients.map((ing) {
                                  return DropdownMenuItem(value: ing.id, child: Text('${ing.name} (${ing.unit})'));
                                }).toList(),
                                onChanged: (newId) {
                                  if (newId == null) return;
                                  final matchingIng = ingredients.firstWhere((i) => i.id == newId);
                                  setState(() {
                                    _recipeSteps[idx] = step.copyWith(
                                      ingredientId: matchingIng.id,
                                      ingredientName: matchingIng.name,
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: step.quantityRequired.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Quantity', isDense: true),
                              onChanged: (val) {
                                double qty = double.tryParse(val) ?? 0.0;
                                _recipeSteps[idx] = step.copyWith(quantityRequired: qty);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _recipeSteps.removeAt(idx);
                                // Re-index remaining sequences immutably
                                for (int i = 0; i < _recipeSteps.length; i++) {
                                  _recipeSteps[i] = _recipeSteps[i].copyWith(stepOrder: i + 1);
                                }
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}