class Ingredient {
  final String id;
  final String name;
  final double currentStock;
  final String unit; // e.g., "ml", "g", "pcs"
  final String category; // e.g., "Dairy", "Syrups", "Toppings"

  const Ingredient({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.category,
  });
}