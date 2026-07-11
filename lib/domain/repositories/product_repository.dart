import 'dart:typed_data';
import '../entities/product.dart';

abstract class ProductRepository {
  // Uploads raw image bytes (highly compatible with Flutter Web) to Cloudinary
  Future<String> uploadImage(Uint8List imageBytes, String fileName);

  // Saves the finalized Product model into Firestore
  Future<void> addProduct(Product product);
}