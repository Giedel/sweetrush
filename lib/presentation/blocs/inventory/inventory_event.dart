import 'package:equatable/equatable.dart';
import '../../../domain/entities/ingredient.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

// Triggered when the app starts or the Inventory page is opened
class LoadInventory extends InventoryEvent {}

// Triggered internally by the BLoC whenever the Firestore stream emits new data
class UpdateInventoryList extends InventoryEvent {
  final List<Ingredient> ingredients;

  const UpdateInventoryList(this.ingredients);

  @override
  List<Object> get props => [ingredients];
}

// Triggered when the user taps a Category ChoiceChip
class FilterInventoryCategory extends InventoryEvent {
  final String category;

  const FilterInventoryCategory(this.category);

  @override
  List<Object> get props => [category];
}

class AddNewIngredient extends InventoryEvent {
  final Ingredient ingredient;

  const AddNewIngredient(this.ingredient);

  @override
  List<Object> get props => [ingredient];
}