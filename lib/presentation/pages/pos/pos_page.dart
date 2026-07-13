import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/pos/pos_bloc.dart';
import '../../blocs/pos/pos_event.dart';
import '../../blocs/pos/pos_state.dart';
import '../../widgets/pos/category_selector.dart';
import '../../widgets/pos/product_card.dart';
import '../../widgets/pos/cart_bottom_sheet.dart';
import '../../widgets/pos/hanging_ticket_dialog.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Trigger initial data load
    context.read<PosBloc>().add(LoadMenuEvent());

    return BlocListener<PosBloc, PosState>(
      listenWhen: (previous, current) => 
          current is PosCheckoutSuccess || current is PosError,
      listener: (context, state) {
        if (state is PosCheckoutSuccess) {
          // Trigger the beautiful hanging receipt overlay window
          HangingTicketDialog.show(context, state.orderedItems, state.totalPaid);
        } else if (state is PosError) {
          // Gracefully notify checkout processing or database errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<PosBloc, PosState>(
        buildWhen: (previous, current) => current is! PosCheckoutSuccess,
        builder: (context, state) {
          if (state is PosLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PosCheckoutSubmitting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Deducting Stock & Generating Ticket...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PosError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is PosLoaded) {
            return Stack(
              children: [
                Column(
                  children: [
                    CategorySelector(selectedCategory: state.selectedCategory),
                    Expanded(
                      child: state.filteredProducts.isEmpty
                          ? const Center(child: Text('No items match this selection.'))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: state.filteredProducts.length,
                              itemBuilder: (_, index) => ProductCard(product: state.filteredProducts[index]),
                            ),
                    ),
                  ],
                ),
                if (state.cartItems.isNotEmpty) 
                  _buildFloatingCartBar(context, state.cartItems, theme),
              ],
            );
          }
          
          return const Center(child: Text('Initializing POS Panel...'));
        },
      ),
    );
  }

  Widget _buildFloatingCartBar(BuildContext context, List dynamicItems, ThemeData theme) {
    final total = dynamicItems.fold<double>(0, (sum, item) => sum + item.price);
    return Positioned(
      left: 16, right: 16, bottom: 96,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => CartBottomSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Badge(
                    label: Text('${dynamicItems.length}'),
                    backgroundColor: theme.colorScheme.onPrimary,
                    textColor: theme.colorScheme.primary,
                    child: Icon(Icons.shopping_bag, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'View Basket',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_up, color: theme.colorScheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}