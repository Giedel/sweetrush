import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Replace these with your actual Cloudinary credentials
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'o2go1aj8', 
    'sweetrush-presets', 
    cache: false,
  );

  @override
  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          tempFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'sweet_rush_products',
        ),
      );

      return response.secureUrl;
    } catch (e) {
      throw Exception("Cloudinary upload failed: $e");
    }
  }

  @override
  Future<void> addProduct(Product product) async {
    final productModel = ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      sizePrices: product.sizePrices,
      imageUrl: product.imageUrl,
      category: product.category,
      recipeSequence: product.recipeSequence,
    );

    await _firestore.collection('products').doc(product.id).set(productModel.toMap());
  }
}