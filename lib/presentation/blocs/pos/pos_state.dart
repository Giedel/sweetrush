import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class PosState extends Equatable {
  const PosState();
  
  @override
  List<Object?> get props => [];
}

class PosInitial extends PosState {}

class PosLoading extends PosState {}

class PosLoaded extends PosState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final List<Product> cartItems;
  final String selectedCategory;
  final String? errorMessage; // ADDED: Allows UI side-effects without losing cart state

  const PosLoaded({
    required this.allProducts,
    required this.filteredProducts,
    required this.cartItems,
    required this.selectedCategory,
    this.errorMessage, // ADDED: Optional parameter fallback
  });

  @override
  List<Object?> get props => [
        allProducts,
        filteredProducts,
        cartItems,
        selectedCategory,
        errorMessage, // ADDED: Track field equality checks safely
      ];
}

class PosCheckoutSubmitting extends PosState {}

class PosCheckoutSuccess extends PosState {
  final List<Product> orderedItems;
  final double totalPaid;

  const PosCheckoutSuccess({
    required this.orderedItems,
    required this.totalPaid,
  });

  @override
  List<Object?> get props => [orderedItems, totalPaid];
}

class PosError extends PosState {
  final String message;

  const PosError(this.message);

  @override
  List<Object?> get props => [message];
}