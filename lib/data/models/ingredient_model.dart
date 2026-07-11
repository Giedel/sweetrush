import '../../domain/entities/ingredient.dart';

class IngredientModel extends Ingredient {
  const IngredientModel({
    required super.id,
    required super.name,
    required super.currentStock,
    required super.unit,
    required super.category,
  });

  factory IngredientModel.fromMap(Map<String, dynamic> map, String documentId) {
    return IngredientModel(
      id: documentId,
      name: map['name'] ?? '',
      currentStock: (map['currentStock'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'currentStock': currentStock,
      'unit': unit,
      'category': category,
    };
  }
}