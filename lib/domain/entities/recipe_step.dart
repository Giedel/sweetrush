class RecipeStep {
  final int stepOrder; // The sequence sequence order (1, 2, 3...)
  final String ingredientId; // Maps to the unique ingredient
  final String ingredientName; // Helpful cache for the kitchen UI layout
  final double quantityRequired;

  const RecipeStep({
    required this.stepOrder,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityRequired,
  });
}