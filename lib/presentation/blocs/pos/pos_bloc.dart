import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/get_menu_products.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final GetMenuProducts getMenuProducts;

  PosBloc({required this.getMenuProducts}) : super(PosInitial()) {
    on<LoadMenuEvent>((event, emit) async {
      emit(PosLoading());
      try {
        final products = await getMenuProducts();
        emit(PosLoaded(
          allProducts: products,
          filteredProducts: products,
          cartItems: const [],
          selectedCategory: 'All',
        ));
      } catch (e) {
        emit(PosError(e.toString()));
      }
    });

    on<FilterMenuCategory>((event, emit) {
      if (state is PosLoaded) {
        final currentState = state as PosLoaded;
        List<Product> filtered;
        
        if (event.category == 'All') {
          filtered = currentState.allProducts;
        } else {
          filtered = currentState.allProducts
              .where((p) => p.selectedSize.toLowerCase() == event.category.toLowerCase())
              .toList();
        }

        emit(PosLoaded(
          allProducts: currentState.allProducts,
          filteredProducts: filtered,
          cartItems: currentState.cartItems,
          selectedCategory: event.category,
        ));
      }
    });

    on<AddToCartEvent>((event, emit) {
      if (state is PosLoaded) {
        final currentState = state as PosLoaded;
        final updatedCart = List<Product>.from(currentState.cartItems)..add(event.product);
        emit(PosLoaded(
          allProducts: currentState.allProducts,
          filteredProducts: currentState.filteredProducts,
          cartItems: updatedCart,
          selectedCategory: currentState.selectedCategory,
        ));
      }
    });

    on<RemoveFromCartEvent>((event, emit) {
      if (state is PosLoaded) {
        final currentState = state as PosLoaded;
        final updatedCart = List<Product>.from(currentState.cartItems)..removeAt(event.index);
        emit(PosLoaded(
          allProducts: currentState.allProducts,
          filteredProducts: currentState.filteredProducts,
          cartItems: updatedCart,
          selectedCategory: currentState.selectedCategory,
        ));
      }
    });

    on<CheckoutCartEvent>((event, emit) async {
      if (state is PosLoaded) {
        final currentState = state as PosLoaded;
        if (currentState.cartItems.isEmpty) return;

        final itemsToCheckOut = List<Product>.from(currentState.cartItems);
        final double subtotal = itemsToCheckOut.fold(0.0, (sum, item) => sum + item.price);

        emit(PosCheckoutSubmitting());
        try {
          await getMenuProducts.repository.checkoutOrder(itemsToCheckOut);
          emit(PosCheckoutSuccess(orderedItems: itemsToCheckOut, totalPaid: subtotal));
        } catch (e) {
          // FAIL-SAFE: Instead of crashing completely to PosError(), we maintain the cart layout 
          // and expose an error description string to the UI.
          String cleanError = e.toString().replaceAll("Exception: ", "");
          
          emit(PosLoaded(
            allProducts: currentState.allProducts,
            filteredProducts: currentState.filteredProducts,
            cartItems: currentState.cartItems,
            selectedCategory: currentState.selectedCategory,
            errorMessage: cleanError, // Handled cleanly via BlocListener inside pos_page.dart!
          ));
        }
      }
    });
  }
}