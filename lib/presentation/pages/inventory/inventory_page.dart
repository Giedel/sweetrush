import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart'; // Add 'uuid: ^4.3.3' to pubspec.yaml for generating IDs
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
    // Fire the load event as soon as the page initializes
    context.read<InventoryBloc>().add(LoadInventory());
  }

  void _showAddIngredientForm(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    String selectedCategory = 'Dairy'; // Default for the dropdown

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ingredient Name'),
                ),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Stock Quantity'),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit (e.g., ml, g, pcs)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: _categories
                      .where((c) => c != 'All') // Don't allow saving as 'All'
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedCategory = value;
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Generate a unique ID (or let Firebase handle it later in the repository)
                final newIngredient = Ingredient(
                  id: const Uuid().v4(), 
                  name: nameController.text,
                  currentStock: double.tryParse(stockController.text) ?? 0.0,
                  unit: unitController.text,
                  category: selectedCategory,
                );

                // Send to BLoC to save to Firebase
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
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
                // Filter Category Row
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
                
                // Inventory List
                Expanded(
                  child: ingredients.isEmpty 
                    ? const Center(child: Text("No items in this category."))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: ingredients.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = ingredients[index];
                          final isLowStock = item.currentStock < 500; 

                          return ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Category: ${item.category}'),
                            trailing: Column(
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