import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/pos/pos_bloc.dart';
import '../../blocs/pos/pos_event.dart';
import '../../blocs/pos/pos_state.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  static void show(BuildContext context) {
    final posBloc = context.read<PosBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: posBloc,
        child: const CartBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state is! PosLoaded || state.cartItems.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Basket is empty', style: TextStyle(color: Colors.grey))),
          );
        }

        final total = state.cartItems.fold<double>(0, (sum, item) => sum + item.price);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined),
                      SizedBox(width: 8),
                      Text('Review Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: state.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = state.cartItems[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          child: const Icon(Icons.cake, size: 20),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.selectedSize} | ${item.sweetnessLevel}', style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => context.read<PosBloc>().add(RemoveFromCartEvent(index)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Dismiss basket
                            _showCashPaymentDialog(context, total); // Open dynamic calculator sheet
                          },
                          child: const Center(
                            child: Text('PROCEED TO PAYMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showCashPaymentDialog(BuildContext context, double totalAmount) {
    final posBloc = context.read<PosBloc>();
    final TextEditingController cashController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            double cashInput = double.tryParse(cashController.text) ?? 0.0;
            double changeDue = cashInput - totalAmount;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Cash Register Intake', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Total: \$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Cash Received',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: changeDue >= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      changeDue >= 0 
                        ? 'Change Due: \$${changeDue.toStringAsFixed(2)}' 
                        : 'Remaining Shortfall: \$${(totalAmount - cashInput).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: changeDue >= 0 ? Colors.green.shade800 : Colors.orange.shade900
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: changeDue < 0 
                    ? null 
                    : () {
                        Navigator.pop(dialogContext);
                        posBloc.add(CheckoutCartEvent(cashReceived: cashInput));
                      },
                  child: const Text('CONFIRM PAID & PRINT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}