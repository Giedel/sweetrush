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

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  Uint8List? _webImage;
  String? _pickedFileName;
  bool _isSaving = false;

  // The active sequence steps being configured for this item
  final List<RecipeStep> _recipeSteps = [];

  // Instantiating the data service directly for simplicity in this view
  final _productRepository = FirebaseProductRepository();

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
    if (availableIngredients.isEmpty) return;
    
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
        const SnackBar(content: Text('Please upload an image, fill details, and add at least one recipe step!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload the image to Cloudinary
      String secureUrl = await _productRepository.uploadImage(_webImage!, _pickedFileName!);

      // 2. Build the Product object
      final targetProduct = Product(
        id: const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        imageUrl: secureUrl,
        recipeSequence: _recipeSteps,
      );

      // 3. Save to Firestore
      await _productRepository.addProduct(targetProduct);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Menu Product')),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is! InventoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final ingredients = state.allIngredients;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Product Metadata
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name (e.g., Mango Frappe)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Selling Price (PHP)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Image Picker Preview Area
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _webImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(_webImage!, fit: BoxFit.cover))
                        : const Center(child: Icon(Icons.add_a_photo_outlined, size: 40)),
                  ),
                ),
                const SizedBox(height: 30),

                // Recipe Configuration Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assembly Recipe Sequence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _addRecipeStep(ingredients),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Step'),
                    )
                  ],
                ),
                const Divider(),

                // List of Configured Steps
                ..._recipeSteps.asMap().entries.map((entry) {
                  int idx = entry.key;
                  RecipeStep step = entry.value;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      key: ValueKey(idx),
                      child: Row(
                        children: [
                          CircleAvatar(child: Text('${step.stepOrder}')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              value: step.ingredientId,
                              isExpanded: true,
                              items: ingredients.map((ing) {
                                return DropdownMenuItem(value: ing.id, child: Text(ing.name));
                              }).toList(),
                              onChanged: (newId) {
                                if (newId == null) return;
                                final matchingIng = ingredients.firstWhere((i) => i.id == newId);
                                setState(() {
                                  _recipeSteps[idx] = RecipeStep(
                                    stepOrder: step.stepOrder,
                                    ingredientId: matchingIng.id,
                                    ingredientName: matchingIng.name,
                                    quantityRequired: step.quantityRequired,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: step.quantityRequired.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(suffixText: 'qty'),
                              onChanged: (val) {
                                double qty = double.tryParse(val) ?? 0.0;
                                _recipeSteps[idx] = RecipeStep(
                                  stepOrder: step.stepOrder,
                                  ingredientId: step.ingredientId,
                                  ingredientName: step.ingredientName,
                                  quantityRequired: qty,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _recipeSteps.removeAt(idx);
                                // Re-index step orders sequentially
                                for (int i = 0; i < _recipeSteps.length; i++) {
                                  _recipeSteps[i] = RecipeStep(
                                    stepOrder: i + 1,
                                    ingredientId: _recipeSteps[i].ingredientId,
                                    ingredientName: _recipeSteps[i].ingredientName,
                                    quantityRequired: _recipeSteps[i].quantityRequired,
                                  );
                                }
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),

                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Save Menu Product'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}