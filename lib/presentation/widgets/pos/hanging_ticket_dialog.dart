import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sweetrush/presentation/blocs/pos/pos_bloc.dart';
import 'package:sweetrush/presentation/blocs/pos/pos_event.dart';
import '../../../domain/entities/product.dart';

class HangingTicketDialog extends StatelessWidget {
  final List<Product> items;
  final double totalPaid;

  const HangingTicketDialog({super.key, required this.items, required this.totalPaid});

  static void show(BuildContext context, List<Product> items, double totalPaid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HangingTicketDialog(items: items, totalPaid: totalPaid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Aluminum Slider Kitchen Bar
              Container(
                height: 14,
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade400,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
              
              // The Main Ticket Sheet
              Container(
                width: 250,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TICKET #KITCHEN', style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('PENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        )
                      ],
                    ),
                    const Divider(height: 20, thickness: 1, color: Colors.black12),
                    
                    // Items List Loop
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('• ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Courier'))),
                                  Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Courier')),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0, top: 2),
                                child: Text(
                                  '[${item.selectedSize}] [${item.sweetnessLevel}]',
                                  style: TextStyle(color: item.isCustomized ? Colors.deepOrange : Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const Divider(height: 24, thickness: 1, color: Colors.black12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL PAID', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Courier', fontSize: 16)),
                        Text('\$${totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Courier', fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              
              // Sawtooth/Jagged Bottom Edge Simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(13, (i) => Icon(Icons.change_history, size: 20, color: Colors.white)).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Done Button out of alignment stack
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog window
                  context.read<PosBloc>().add(LoadMenuEvent()); // Refresh home grid states
                },
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text('DISMISS TICKET', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}