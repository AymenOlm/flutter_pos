import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/pos/data/repositories/sales_repository_impl.dart';
import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/features/admin/presentation/views/admin_home_view.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> login({required String username, required String password}) {
    return Future<AppUser>.value(
      AppUser(id: 'u-1', username: username, role: UserRole.admin),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> getProducts() async => products;

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<void> upsertProduct(Product product) async {}
}

class _FakeSalesLocalDataSource implements SalesLocalDataSource {
  _FakeSalesLocalDataSource(this.transactions);

  final List<TransactionRecord> transactions;

  @override
  Future<List<TransactionRecord>> getTransactions() async => transactions;

  @override
  Future<void> saveTransaction(TransactionRecord record) async {}
}

TransactionRecord _buildTransaction({
  required String id,
  required DateTime createdAt,
  required String paymentMethod,
  required String itemName,
  required int quantity,
  required double price,
}) {
  final product = Product(
    id: '$id-product',
    name: itemName,
    price: price,
    category: 'Beverages',
  );
  final cart = CartEntity(
    items: [CartItemEntity(product: product, quantity: quantity)],
  );
  const calculateTotal = CalculateTotal();
  final totals = calculateTotal(cart);

  return TransactionRecord(
    id: id,
    createdAt: createdAt,
    paymentMethod: paymentMethod,
    cart: cart,
    subtotal: totals.subtotal,
    discountType: DiscountType.fixed,
    discountValue: 0,
    discountAmount: 0,
    total: totals.total,
  );
}

Future<void> _registerAdminDependencies({
  required List<TransactionRecord> transactions,
}) async {
  await sl.reset();
  sl.registerSingleton<AuthRepository>(_FakeAuthRepository());
  sl.registerSingleton<ProductRepository>(
    _FakeProductRepository(const [
      Product(id: 'p-1', name: 'Coffee', price: 3.50, category: 'Beverages'),
      Product(id: 'p-2', name: 'Tea', price: 2.50, category: 'Beverages'),
    ]),
  );
  sl.registerSingleton<SalesRepository>(
    SalesRepositoryImpl(_FakeSalesLocalDataSource(transactions)),
  );
}

Widget _buildAdminApp(AuthBloc authBloc) {
  return MaterialApp(
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const AdminHomeView(),
    ),
  );
}

void main() {
  AuthBloc? authBloc;

  tearDown(() async {
    await authBloc?.close();
    authBloc = null;
    await sl.reset();
  });

  testWidgets('filters sales by date and search', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final transactions = [
      _buildTransaction(
        id: 'txn-100',
        createdAt: now,
        paymentMethod: 'Cash',
        itemName: 'Coffee',
        quantity: 2,
        price: 3.50,
      ),
      _buildTransaction(
        id: 'txn-200',
        createdAt: now.subtract(const Duration(days: 10)),
        paymentMethod: 'Card',
        itemName: 'Tea',
        quantity: 1,
        price: 2.50,
      ),
    ];

    await _registerAdminDependencies(transactions: transactions);
    authBloc = AuthBloc(
      getCurrentUser: GetCurrentUser(_FakeAuthRepository()),
      login: Login(_FakeAuthRepository()),
      logout: Logout(_FakeAuthRepository()),
    );

    await tester.pumpWidget(_buildAdminApp(authBloc!));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction #txn-100'), findsOneWidget);
    expect(find.text('Transaction #txn-200'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Coffee');
    await tester.pumpAndSettle();

    expect(find.text('Transaction #txn-100'), findsOneWidget);
    expect(find.text('Transaction #txn-200'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Today'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction #txn-100'), findsOneWidget);
    expect(find.text('Transaction #txn-200'), findsNothing);
  });

  testWidgets('opens transaction detail view from sales history', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final transactions = [
      _buildTransaction(
        id: 'txn-300',
        createdAt: now,
        paymentMethod: 'Card',
        itemName: 'Coffee',
        quantity: 2,
        price: 3.50,
      ),
    ];

    await _registerAdminDependencies(transactions: transactions);
    authBloc = AuthBloc(
      getCurrentUser: GetCurrentUser(_FakeAuthRepository()),
      login: Login(_FakeAuthRepository()),
      logout: Logout(_FakeAuthRepository()),
    );

    await tester.pumpWidget(_buildAdminApp(authBloc!));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transaction #txn-300'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction Details'), findsOneWidget);
    expect(find.text('Transaction #txn-300'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Totals'), findsOneWidget);
  });
}
