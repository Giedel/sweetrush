import '../../../domain/entities/product.dart';

abstract class PosEvent {}

class LoadMenuEvent extends PosEvent {}
class CheckoutCartEvent extends PosEvent {}

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