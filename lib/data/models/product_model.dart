import '../../domain/entities/product.dart';
import 'recipe_step_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.sizePrices,
    required super.imageUrl,
    required super.category,
    required super.recipeSequence,
    super.selectedSize, // Inherits the default 'Regular' value cleanly
    super.sweetnessLevel, // Inherits the default 'Normal Sweet' value cleanly
    super.isCustomized, // Inherits the default false value cleanly
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    var rawSequence = map['recipeSequence'] as List<dynamic>? ?? [];
    
    List<RecipeStepModel> parsedSequence = rawSequence
        .map((step) => RecipeStepModel.fromMap(Map<String, dynamic>.from(step)))
        .toList();

    parsedSequence.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    // Handle extraction of nested map double variances safely
    Map<String, double> parsedSizePrices = {};
    if (map['sizePrices'] != null) {
      (map['sizePrices'] as Map<dynamic, dynamic>).forEach((key, value) {
        parsedSizePrices[key.toString()] = (value ?? 0.0).toDouble();
      });
    }

    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      sizePrices: parsedSizePrices,
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'Cakes',
      recipeSequence: parsedSequence,
      selectedSize: map['selectedSize'] ?? 'Regular',
      sweetnessLevel: map['sweetnessLevel'] ?? 'Normal Sweet',
      isCustomized: map['isCustomized'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'sizePrices': sizePrices, // Firestore natively recognizes Map structures flatly
      'imageUrl': imageUrl,
      'category': category,
      'selectedSize': selectedSize,
      'sweetnessLevel': sweetnessLevel,
      'isCustomized': isCustomized,
      'recipeSequence': recipeSequence
          .map((step) => RecipeStepModel(
                stepOrder: step.stepOrder,
                ingredientId: step.ingredientId,
                ingredientName: step.ingredientName,
                quantityRequired: step.quantityRequired,
              ).toMap())
          .toList(),
    };
  }
}