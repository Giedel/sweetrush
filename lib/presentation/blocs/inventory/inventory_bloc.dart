import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/inventory_repository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _inventoryRepository;
  StreamSubscription? _inventorySubscription;

  // Constructor injecting the repository and registering event handlers
  InventoryBloc({required InventoryRepository inventoryRepository})
      : _inventoryRepository = inventoryRepository,
        super(InventoryLoading()) {
    on<LoadInventory>(_onLoadInventory);
    on<UpdateInventoryList>(_onUpdateInventoryList);
    on<FilterInventoryCategory>(_onFilterInventoryCategory);
    on<AddNewIngredient>(_onAddNewIngredient);
    on<UpdateIngredientStock>(_onUpdateIngredientStock); // REGISTERED NEW EVENT HANDLER
  }

  void _onLoadInventory(LoadInventory event, Emitter<InventoryState> emit) {
    emit(InventoryLoading());
    
    // Cancel any existing subscription before creating a new one
    _inventorySubscription?.cancel();
    
    // Listen to the Firestore stream. Whenever it yields new data, 
    // we pipe it back into the BLoC as an UpdateInventoryList event.
    _inventorySubscription = _inventoryRepository.getInventoryStream().listen(
      (ingredients) {
        add(UpdateInventoryList(ingredients));
      },
      onError: (error) {
        emit(InventoryError("Failed to load inventory: $error"));
      },
    );
  }

  void _onUpdateInventoryList(UpdateInventoryList event, Emitter<InventoryState> emit) {
    // If the state is already loaded, we maintain the currently selected category.
    // Otherwise, we default to 'All'.
    final currentCategory = state is InventoryLoaded 
        ? (state as InventoryLoaded).selectedCategory 
        : 'All';

    // Apply the filter logic immediately upon receiving new data
    final filteredList = currentCategory == 'All'
        ? event.ingredients
        : event.ingredients.where((i) => i.category == currentCategory).toList();

    emit(InventoryLoaded(
      allIngredients: event.ingredients,
      filteredIngredients: filteredList,
      selectedCategory: currentCategory,
    ));
  }

  void _onFilterInventoryCategory(FilterInventoryCategory event, Emitter<InventoryState> emit) {
    // We can only filter if the data is actually loaded
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      
      final filteredList = event.category == 'All'
          ? currentState.allIngredients
          : currentState.allIngredients.where((i) => i.category == event.category).toList();

      emit(InventoryLoaded(
        allIngredients: currentState.allIngredients,
        filteredIngredients: filteredList,
        selectedCategory: event.category,
      ));
    }
  }

  Future<void> _onAddNewIngredient(AddNewIngredient event, Emitter<InventoryState> emit) async {
    try {
      // Tell the repository to save the new ingredient.
      // The Firestore stream will detect the change and automatically trigger UpdateInventoryList.
      await _inventoryRepository.addIngredient(event.ingredient);
    } catch (e) {
      print("Error saving ingredient: $e");
    }
  }

  // NEW METHOD: Dispatches calculations down to the database asynchronously
  Future<void> _onUpdateIngredientStock(UpdateIngredientStock event, Emitter<InventoryState> emit) async {
    try {
      await _inventoryRepository.updateIngredientStock(
        ingredientId: event.ingredientId,
        quantityChange: event.quantityChange,
        isOverride: event.isOverride,
      );
      // Realtime snapshots from getInventoryStream handle emitting the updated list automatically!
    } catch (e) {
      print("Error updating stock execution: $e");
    }
  }

  @override
  Future<void> close() {
    // Always dispose of the stream subscription when the BLoC is closed
    _inventorySubscription?.cancel();
    return super.close();
  }
}