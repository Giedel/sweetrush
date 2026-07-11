import '../entities/ingredient.dart';

abstract class InventoryRepository {
  // Returns a live stream of ingredients from Firestore
  Stream<List<Ingredient>> getInventoryStream();
  
  // Future method for when we add the ingredient form
  Future<void> addIngredient(Ingredient ingredient);
}