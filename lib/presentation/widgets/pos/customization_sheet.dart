import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/pos/pos_bloc.dart';
import '../../blocs/pos/pos_event.dart';

class CustomizationSheet extends StatefulWidget {
  final Product product;
  const CustomizationSheet({super.key, required this.product});

  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CustomizationSheet(product: product),
    );
  }

  @override
  State<CustomizationSheet> createState() => _CustomizationSheetState();
}

class _CustomizationSheetState extends State<CustomizationSheet> {
  String _selectedSize = 'Regular';
  String _sweetnessLevel = 'Normal Sweet';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(widget.product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('\$${widget.product.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Image
                  Container(
                    height: 140,
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: widget.product.imageUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.product.imageUrl, fit: BoxFit.cover))
                        : Icon(Icons.fastfood, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),

                  // Size selection
                  const Text('Select Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Small', 'Regular', 'Large'].map((size) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(size),
                          selected: _selectedSize == size,
                          onSelected: (val) { if (val) setState(() => _selectedSize = size); },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Sweetness
                  const Text('Sweetness Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _sweetnessLevel,
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: ['Less Sweet', 'Normal Sweet', 'Extra Sweet'].map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                    onChanged: (val) { if (val != null) setState(() => _sweetnessLevel = val); },
                  ),
                  const SizedBox(height: 24),

                  // Mix Formula
                  const Text('Default Mix Recipe Sequence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  widget.product.recipeSequence.isEmpty
                      ? const Text('Standard standalone product.', style: TextStyle(color: Colors.grey))
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            children: widget.product.recipeSequence.map((step) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    CircleAvatar(radius: 10, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text('${step.stepOrder}', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 10),
                                    Text(step.ingredientName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text('${step.quantityRequired}', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
            
            // Add padding around the button to make the layout look polished
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final isCustom = _selectedSize != 'Regular' || _sweetnessLevel != 'Normal Sweet';
                    final customized = widget.product.copyWith(
                      selectedSize: _selectedSize,
                      sweetnessLevel: _sweetnessLevel,
                      isCustomized: isCustom,
                    );
                    context.read<PosBloc>().add(AddToCartEvent(customized));
                    Navigator.pop(context);
                  },
                  child: const Center(child: Text('ADD TO BASKET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}