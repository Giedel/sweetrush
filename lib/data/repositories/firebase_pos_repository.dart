import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/pos_repository.dart';
import '../models/product_model.dart';

class FirebasePosRepository implements PosRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Product>> getMenuProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu products: $e');
    }
  }

  @override
  Future<void> checkoutOrder(List<Product> cartItems) async {
    if (cartItems.isEmpty) return;

    // Execute atomic batch transaction
    await _firestore.runTransaction((transaction) async {
      
      // 1. Gather all required ingredient deductions based on the recipe mixes
      final Map<String, double> totalDeductions = {};

      for (var product in cartItems) {
        for (var step in product.recipeSequence) {
          final currentNeeded = step.quantityRequired;
          totalDeductions[step.ingredientId] = (totalDeductions[step.ingredientId] ?? 0) + currentNeeded;
        }
      }

      // 2. Read current ingredient documents and calculate new balances
      final Map<DocumentReference, double> pendingStockUpdates = {};
      
      for (var ingredientId in totalDeductions.keys) {
        // CORRECTION: Collection name updated to point to 'inventory' to match your stock registers
        final ingredientRef = _firestore.collection('inventory').doc(ingredientId);
        final docSnapshot = await transaction.get(ingredientRef);

        // FAIL-SAFE: Log a warning instead of a crash if an ID was removed from inventory mid-testing
        if (!docSnapshot.exists) {
          print('WARNING: Ingredient ID "$ingredientId" missing from registers. Skipping deduction calculations.');
          continue; 
        }

        final double currentStock = (docSnapshot.data()?['currentStock'] ?? 0.0).toDouble();
        final double deductionAmount = totalDeductions[ingredientId]!;
        final double newStockValue = currentStock - deductionAmount;

        if (newStockValue < 0) {
          final String name = docSnapshot.data()?['name'] ?? 'Unknown Ingredient';
          throw Exception('Insufficient stock for $name ($currentStock remaining).');
        }

        pendingStockUpdates[ingredientRef] = newStockValue;
      }

      // 3. Write changes to ingredients
      pendingStockUpdates.forEach((ref, nextStockValue) {
        transaction.update(ref, {'currentStock': nextStockValue});
      });

      // 4. Create the Hanging Ticket in the orders collection
      final orderRef = _firestore.collection('orders').doc();
      final double totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.price);

      final orderData = {
        'id': orderRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'totalAmount': totalAmount,
        'status': 'Pending',
        'items': cartItems.map((item) => {
          'productId': item.id,
          'name': item.name,
          'price': item.price,
          'selectedSize': item.selectedSize,
          'sweetnessLevel': item.sweetnessLevel,
          'isCustomized': item.isCustomized,
          'recipeSequence': item.recipeSequence.map((step) => {
            'stepOrder': step.stepOrder,
            'ingredientName': step.ingredientName,
            'quantityRequired': step.quantityRequired,
          }).toList(),
        }).toList(),
      };

      transaction.set(orderRef, orderData);
    });
  }
}