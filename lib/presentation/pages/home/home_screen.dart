import 'package:flutter/material.dart';
import 'package:sweetrush/presentation/pages/pos/pos_page.dart';
import 'package:sweetrush/presentation/pages/pos/back_of_house_page.dart'; // IMPORT ADDED HERE
import 'package:sweetrush/presentation/pages/inventory/inventory_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // UPDATED: Replaced hardcoded text layout with the real-time Stream layer
  final List<Widget> _pages = [
    const PosPage(),
    const BackOfHousePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      appBar: AppBar(
        title: const Text('Sweet Rush POS', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Manage Inventory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale_rounded),
                  label: 'Front',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.kitchen_rounded),
                  label: 'Back',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}