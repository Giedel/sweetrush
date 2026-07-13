import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/ingredient_model.dart';

class FirebaseInventoryRepository implements InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Ingredient>> getInventoryStream() {
    return _firestore.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IngredientModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addIngredient(Ingredient ingredient) async {
    final ingredientModel = IngredientModel(
      id: ingredient.id,
      name: ingredient.name,
      currentStock: ingredient.currentStock,
      unit: ingredient.unit,
      category: ingredient.category,
    );
    await _firestore.collection('inventory').doc(ingredient.id).set(ingredientModel.toMap());
  }

  // ADD THIS METHOD IMPLEMENTATION:
  @override
  Future<void> updateIngredientStock({
    required String ingredientId,
    required double quantityChange,
    required bool isOverride,
  }) async {
    final docRef = _firestore.collection('inventory').doc(ingredientId);

    if (isOverride) {
      // Set absolute value manually
      await docRef.update({'currentStock': quantityChange});
    } else {
      // Perform atomic database field calculation increments
      await docRef.update({'currentStock': FieldValue.increment(quantityChange)});
    }
  }
}