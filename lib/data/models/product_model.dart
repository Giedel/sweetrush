import '../../domain/entities/product.dart';
import 'recipe_step_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
    required super.recipeSequence,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    var rawSequence = map['recipeSequence'] as List<dynamic>? ?? [];
    
    List<RecipeStepModel> parsedSequence = rawSequence
        .map((step) => RecipeStepModel.fromMap(Map<String, dynamic>.from(step)))
        .toList();

    // Ensure sequence follows chronological execution sorting (1, 2, 3...)
    parsedSequence.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      recipeSequence: parsedSequence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
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