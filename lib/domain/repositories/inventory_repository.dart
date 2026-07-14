import '../entities/ingredient.dart';

abstract class InventoryRepository {
  Stream<List<Ingredient>> getInventoryStream();
  Future<void> addIngredient(Ingredient ingredient);

  Future<void> updateIngredientStock({
    required String ingredientId,
    required double quantityChange,
    required bool isOverride,
  });
}