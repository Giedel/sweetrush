import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackOfHousePage extends StatelessWidget {
  const BackOfHousePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'Pending')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Kitchen Queue is Empty ☕', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final List items = order['items'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Text('Ticket #${orders[index].id.substring(0, 5).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${items.length} Items Pending Production Mix'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('orders').doc(orders[index].id).update({'status': 'Completed'});
                    },
                    child: const Text('DONE'),
                  ),
                  children: items.map<Widget>((item) {
                    return ListTile(
                      title: Text('${item['name']} (${item['selectedSize']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Sweetness: ${item['sweetnessLevel']}'),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}