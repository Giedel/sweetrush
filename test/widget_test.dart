import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetrush/domain/entities/ingredient.dart';
import 'package:sweetrush/domain/repositories/inventory_repository.dart';
import 'package:sweetrush/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:sweetrush/presentation/blocs/inventory/inventory_state.dart';
import 'package:sweetrush/presentation/pages/inventory/add_product_page.dart';

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<void> addIngredient(Ingredient ingredient) async {}

  @override
  Stream<List<Ingredient>> getInventoryStream() => const Stream.empty();

  @override
  Future<void> updateIngredientStock({
    required String ingredientId,
    required double quantityChange,
    required bool isOverride,
  }) async {}
}

class _TestInventoryBloc extends InventoryBloc {
  _TestInventoryBloc()
      : super(inventoryRepository: _FakeInventoryRepository());

  void setState(InventoryState state) => emit(state);
}

void main() {
  testWidgets('AddProductPage shows inventory error message',
      (WidgetTester tester) async {
    final bloc = _TestInventoryBloc()..setState(const InventoryError('Boom'));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<InventoryBloc>.value(
          value: bloc,
          child: const AddProductPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Boom'), findsOneWidget);

    await bloc.close();
  });
}
