import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/ingredient_model.dart';

class FirebaseInventoryRepository implements InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to sanitize floating-point anomalies to 2 decimal places
  double _sanitizeDouble(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  @override
  Stream<List<Ingredient>> getInventoryStream() {
    return _firestore.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Sanitize the currentStock coming FROM Firestore just in case old corrupted data exists
        if (data.containsKey('currentStock') && data['currentStock'] is num) {
          data['currentStock'] = _sanitizeDouble((data['currentStock'] as num).toDouble());
        }

        return IngredientModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addIngredient(Ingredient ingredient) async {
    // Sanitize the currentStock BEFORE it ever gets saved to Firestore
    final sanitizedStock = _sanitizeDouble(ingredient.currentStock);

    final ingredientModel = IngredientModel(
      id: ingredient.id,
      name: ingredient.name,
      currentStock: sanitizedStock, // Cleaned value
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