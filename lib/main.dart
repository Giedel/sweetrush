import 'package:sweetrush/firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/pages/home/home_screen.dart';
import 'package:sweetrush/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:sweetrush/data/repositories/firebase_inventory_repository.dart';

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
        // Inject the BLoC and give it the Firebase repository
        BlocProvider<InventoryBloc>(
          create: (context) => InventoryBloc(
            inventoryRepository: FirebaseInventoryRepository(),
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