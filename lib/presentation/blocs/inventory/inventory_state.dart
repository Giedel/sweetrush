import 'package:equatable/equatable.dart';
import '../../../domain/entities/ingredient.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  
  @override
  List<Object> get props => [];
}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Ingredient> allIngredients;
  final List<Ingredient> filteredIngredients;
  final String selectedCategory;

  const InventoryLoaded({
    required this.allIngredients,
    required this.filteredIngredients,
    this.selectedCategory = 'All',
  });

  @override
  List<Object> get props => [allIngredients, filteredIngredients, selectedCategory];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object> get props => [message];
}