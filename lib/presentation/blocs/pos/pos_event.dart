import '../../../domain/entities/product.dart';

abstract class PosEvent {}

class LoadMenuEvent extends PosEvent {}

// UPDATED: Now requires cash amount parameter
class CheckoutCartEvent extends PosEvent {
  final double cashReceived;
  CheckoutCartEvent({required this.cashReceived});
}

class FilterMenuCategory extends PosEvent {
  final String category;
  FilterMenuCategory(this.category);
}

class AddToCartEvent extends PosEvent {
  final Product product;
  AddToCartEvent(this.product);
}

class RemoveFromCartEvent extends PosEvent {
  final int index;
  RemoveFromCartEvent(this.index);
}