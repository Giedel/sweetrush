import '../entities/kitchen_ticket.dart';

abstract class KitchenRepository {
  Stream<List<KitchenTicket>> watchPendingOrders();
  Future<void> completeOrder(String orderId);
}
