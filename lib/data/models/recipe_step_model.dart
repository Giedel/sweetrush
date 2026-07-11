import '../../domain/entities/recipe_step.dart';

class RecipeStepModel extends RecipeStep {
  const RecipeStepModel({
    required super.stepOrder,
    required super.ingredientId,
    required super.ingredientName,
    required super.quantityRequired,
  });

  factory RecipeStepModel.fromMap(Map<String, dynamic> map) {
    return RecipeStepModel(
      stepOrder: map['stepOrder'] ?? 0,
      ingredientId: map['ingredientId'] ?? '',
      ingredientName: map['ingredientName'] ?? '',
      quantityRequired: (map['quantityRequired'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepOrder': stepOrder,
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'quantityRequired': quantityRequired,
    };
  }
}