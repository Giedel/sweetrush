import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/entities/recipe_step.dart';

class KitchenTicketModel extends KitchenTicket {
  const KitchenTicketModel({
    required super.id,
    required super.status,
    required super.items,
    super.timestamp,
  });

  factory KitchenTicketModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((rawItem) => _parseItem(Map<String, dynamic>.from(rawItem as Map)))
        .toList();

    return KitchenTicketModel(
      id: id,
      status: map['status'] ?? 'Pending',
      timestamp: _parseTimestamp(map['timestamp']),
      items: items,
    );
  }

  static KitchenTicketItem _parseItem(Map<String, dynamic> item) {
    final rawSequence = item['recipeSequence'] as List<dynamic>? ?? [];
    final sequence = rawSequence
        .map((rawStep) => _parseRecipeStep(Map<String, dynamic>.from(rawStep as Map)))
        .toList()
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return KitchenTicketItem(
      productId: item['productId'] ?? '',
      name: item['name'] ?? 'Unknown',
      selectedSize: item['selectedSize'] ?? 'Regular',
      sweetnessLevel: item['sweetnessLevel'] ?? 'Normal Sweet',
      recipeSequence: sequence,
    );
  }

  static RecipeStep _parseRecipeStep(Map<String, dynamic> step) {
    final ingredientName = step['ingredientName'] ?? '';
    final ingredientId = (step['ingredientId'] ?? '').toString();
    return RecipeStep(
      stepOrder: step['stepOrder'] ?? 0,
      ingredientId: ingredientId,
      ingredientName: ingredientName,
      quantityRequired: (step['quantityRequired'] ?? 0).toDouble(),
    );
  }

  static DateTime? _parseTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp == null) return null;
    if (rawTimestamp is DateTime) return rawTimestamp;
    if (rawTimestamp is Timestamp) return rawTimestamp.toDate();
    if (rawTimestamp is String) return DateTime.tryParse(rawTimestamp);
    if (rawTimestamp is num) {
      return DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt());
    }
    return null;
  }
}
