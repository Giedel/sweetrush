import 'package:sweetrush/firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/pages/home/home_screen.dart';

// Repositories & Use Cases
import 'package:sweetrush/data/repositories/firebase_inventory_repository.dart';
import 'package:sweetrush/data/repositories/firebase_pos_repository.dart';
import 'package:sweetrush/domain/usecases/get_menu_products.dart';

// Blocs
import 'package:sweetrush/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:sweetrush/presentation/blocs/pos/pos_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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