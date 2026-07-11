import 'recipe_step.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl; // Settled secure Cloudinary URL
  final List<RecipeStep> recipeSequence;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.recipeSequence,
  });
}