import 'recipe_step.dart';

class KitchenTicket {
  final String id;
  final DateTime? timestamp;
  final String status;
  final List<KitchenTicketItem> items;

  const KitchenTicket({
    required this.id,
    required this.status,
    required this.items,
    this.timestamp,
  });
}

class KitchenTicketItem {
  final String productId;
  final String name;
  final String selectedSize;
  final String sweetnessLevel;
  final List<RecipeStep> recipeSequence;

  const KitchenTicketItem({
    required this.productId,
    required this.name,
    required this.selectedSize,
    required this.sweetnessLevel,
    required this.recipeSequence,
  });
}
