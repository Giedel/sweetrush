import 'package:sweetrush/firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/pages/home/home_screen.dart';

// Repositories & Use Cases
import 'package:sweetrush/data/repositories/firebase_inventory_repository.dart';
import 'package:sweetrush/data/repositories/firebase_pos_repository.dart';
import 'package:sweetrush/data/repositories/firebase_kitchen_repository.dart'; // IMPORTED FOR SYNC
import 'package:sweetrush/domain/usecases/get_menu_products.dart';

// Blocs
import 'package:sweetrush/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:sweetrush/presentation/blocs/pos/pos_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SweetRushApp());
}

class SweetRushApp extends StatelessWidget {
  const SweetRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Inventory BLoC
        BlocProvider<InventoryBloc>(
          create: (context) => InventoryBloc(
            inventoryRepository: FirebaseInventoryRepository(),
          ),
        ),
        // POS BLoC with UseCase injection
        BlocProvider<PosBloc>(
          create: (context) => PosBloc(
            getMenuProducts: GetMenuProducts(
              FirebasePosRepository(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sweet Rush POS',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

import 'package:sweetrush/presentation/pages/pos/pos_page.dart';
import 'package:sweetrush/presentation/pages/pos/back_of_house_page.dart'; 
import 'package:sweetrush/presentation/pages/inventory/inventory_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // UPDATED: Now correctly passing Firebase repositories to avoid mock data fallback
  final List<Widget> _pages = [
    const PosPage(),
    BackOfHousePage(
      kitchenRepository: FirebaseKitchenRepository(),
      inventoryRepository: FirebaseInventoryRepository(),
    ),
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
                color: Colors.black.withOpacity(0.1),
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