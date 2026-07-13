class RecipeStep {
  final int stepOrder; // The sequence sequence order (1, 2, 3...)
  final String ingredientId; // Maps to the unique ingredient
  final String ingredientName;
  final double quantityRequired;

  const RecipeStep({
    required this.stepOrder,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityRequired,
  });

  RecipeStep copyWith({
    int? stepOrder,
    String? ingredientId,
    String? ingredientName,
    double? quantityRequired,
  }) {
    return RecipeStep(
      stepOrder: stepOrder ?? this.stepOrder,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantityRequired: quantityRequired ?? this.quantityRequired,
    );
  }
}