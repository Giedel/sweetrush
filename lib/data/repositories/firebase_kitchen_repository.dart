import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_repository.dart';
import '../models/kitchen_ticket_model.dart';

class FirebaseKitchenRepository implements KitchenRepository {
  final FirebaseFirestore _firestore;

  FirebaseKitchenRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<KitchenTicket>> watchPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Pending')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => KitchenTicketModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> completeOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
