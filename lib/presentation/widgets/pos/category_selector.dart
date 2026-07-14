import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/pos/pos_bloc.dart';
import '../../blocs/pos/pos_event.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  const CategorySelector({super.key, required this.selectedCategory});

  final List<String> _categories = const ['All', 'Cakes', 'Pastries', 'Drinks', 'Seasonal'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
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
              selected: selectedCategory == category,
              onSelected: (selected) {
                if (selected) {
                  context.read<PosBloc>().add(FilterMenuCategory(category));
                }
              },
            ),
          );
        },
      ),
    );
  }
}