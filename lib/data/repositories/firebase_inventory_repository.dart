import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/ingredient_model.dart';

class FirebaseInventoryRepository implements InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Ingredient>> getInventoryStream() {
    // Listens to the 'inventory' collection in real-time
    return _firestore.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Convert the Firestore map back into our entity using our model mapping
        return IngredientModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addIngredient(Ingredient ingredient) async {
    // Convert the pure entity into a model so we can call toMap()
    final ingredientModel = IngredientModel(
      id: ingredient.id,
      name: ingredient.name,
      currentStock: ingredient.currentStock,
      unit: ingredient.unit,
      category: ingredient.category,
    );

    // Save it to Firestore using the generated UUID as the document ID
    await _firestore.collection('inventory').doc(ingredient.id).set(ingredientModel.toMap());
  }
}