import '../entities/product.dart';
import '../repositories/pos_repository.dart';

class GetMenuProducts {
  final PosRepository repository;

  GetMenuProducts(this.repository);

  Future<List<Product>> call() async {
    return await repository.getMenuProducts();
  }
}