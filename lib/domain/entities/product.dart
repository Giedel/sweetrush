import 'recipe_step.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final Map<String, double> sizePrices; // e.g., {"Small": 120, "Regular": 150, "Large": 180}
  final String imageUrl;
  final String category;
  final List<RecipeStep> recipeSequence;
  final String selectedSize;
  final String sweetnessLevel;
  final bool isCustomized; 

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sizePrices,
    required this.imageUrl,
    required this.category, // <-- Require it here
    required this.recipeSequence,
    this.selectedSize = 'Regular',
    this.sweetnessLevel = 'Normal Sweet',
    this.isCustomized = false,
  });

  Product copyWith({
    String? selectedSize,
    String? sweetnessLevel,
    bool? isCustomized,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      sizePrices: sizePrices,
      imageUrl: imageUrl,
      category: category, // Keep category safe during copy operations
      recipeSequence: recipeSequence,
      selectedSize: selectedSize ?? this.selectedSize,
      sweetnessLevel: sweetnessLevel ?? this.sweetnessLevel,
      isCustomized: isCustomized ?? this.isCustomized,
    );
  }
}