import '../entities/product.dart';

abstract class PosRepository {
  Future<List<Product>> getMenuProducts();
  Future<void> checkoutOrder(List<Product> cartItems);
}