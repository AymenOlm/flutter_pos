import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/auth/presentation/views/login_view.dart';
import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';
import 'package:flutter_pos/features/pos/data/datasources/cart_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/features/pos/presentation/views/pos_view.dart';
import 'package:flutter_pos/main.dart';

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

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginError});

  final Object? loginError;

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> login({required String username, required String password}) {
    if (loginError != null) {
      return Future<AppUser>.error(loginError!);
    }

    return Future<AppUser>.value(
      AppUser(id: 'u-1', username: username, role: UserRole.seller),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeSalesRepository implements SalesRepository {
  final List<TransactionRecord> savedTransactions = <TransactionRecord>[];

  @override
  Future<void> saveTransaction(TransactionRecord record) async {
    savedTransactions.add(record);
  }

  @override
  Future<List<TransactionRecord>> getTransactions() async =>
      List<TransactionRecord>.unmodifiable(savedTransactions);
}

class _FakeCartLocalDataSource implements CartLocalDataSource {
  PersistedCartState? loadedState;
  CartEntity? savedCart;
  CartDiscount? savedDiscount;
  int clearCalls = 0;

  @override
  Future<void> clearCartState() async {
    clearCalls += 1;
  }

  @override
  Future<PersistedCartState?> loadCartState() async => loadedState;

  @override
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) async {
    savedCart = cart;
    savedDiscount = discount;
  }
}

Finder _fieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

Widget _buildPosShell({
  required CartBloc cartBloc,
  required ProductCatalogBloc productCatalogBloc,
}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>.value(value: cartBloc),
        BlocProvider<ProductCatalogBloc>.value(value: productCatalogBloc),
      ],
      child: const POSView(),
    ),
  );
}

CartBloc _buildCartBloc({
  PersistedCartState? loadedState,
  _FakeSalesRepository? salesRepository,
  _FakeCartLocalDataSource? cartLocalDataSource,
}) {
  final source = cartLocalDataSource ?? _FakeCartLocalDataSource();
  source.loadedState = loadedState;
  final repository = salesRepository ?? _FakeSalesRepository();

  return CartBloc(
    calculateTotal: const CalculateTotal(),
    saveTransaction: SaveTransaction(repository),
    logger: AppLogger(sinks: const []),
    cartLocalDataSource: source,
  );
}

ProductCatalogBloc _buildCatalogBloc(List<Product> products) {
  final bloc = ProductCatalogBloc(
    repository: _FakeProductRepository(products),
    logger: AppLogger(sinks: const []),
  );
  bloc.add(const LoadProducts());
  return bloc;
}

void main() {
  testWidgets('Login screen renders when no session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await initPosDependencies();
    await sl<AuthRepository>().logout();
    await tester.pumpWidget(const POSApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('POS Login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('filters products by search and category', (
    WidgetTester tester,
  ) async {
    final cartBloc = _buildCartBloc();
    final productCatalogBloc = _buildCatalogBloc(const [
      Product(id: 'p-1', name: 'Coffee', price: 3.50, category: 'Beverages'),
      Product(id: 'p-2', name: 'Tea', price: 2.50, category: 'Beverages'),
      Product(id: 'p-3', name: 'Sandwich', price: 7.25, category: 'Food'),
    ]);
    addTearDown(() async {
      await cartBloc.close();
      await productCatalogBloc.close();
    });

    await tester.pumpWidget(
      _buildPosShell(
        cartBloc: cartBloc,
        productCatalogBloc: productCatalogBloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('Sandwich'), findsOneWidget);

    await tester.enterText(_fieldWithLabel('Search products'), 'cof');
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Tea'), findsNothing);
    expect(find.text('Sandwich'), findsNothing);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No products match those filters. Try clearing filters or searching different terms.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the desktop POS layout smoke test', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cartBloc = _buildCartBloc();
    final productCatalogBloc = _buildCatalogBloc(const [
      Product(id: 'p-1', name: 'Coffee', price: 3.50, category: 'Beverages'),
      Product(id: 'p-2', name: 'Tea', price: 2.50, category: 'Beverages'),
    ]);
    addTearDown(() async {
      await cartBloc.close();
      await productCatalogBloc.close();
    });

    await tester.pumpWidget(
      _buildPosShell(
        cartBloc: cartBloc,
        productCatalogBloc: productCatalogBloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POS Console'), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  testWidgets('updates cart quantity and persists the new total', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cartLocalDataSource = _FakeCartLocalDataSource();
    final coffee = const Product(
      id: 'p-1',
      name: 'Coffee',
      price: 3.50,
      category: 'Beverages',
    );
    final cartBloc = _buildCartBloc(
      loadedState: PersistedCartState(
        cart: CartEntity(items: [CartItemEntity(product: coffee, quantity: 1)]),
        discount: const CartDiscount.none(),
      ),
      cartLocalDataSource: cartLocalDataSource,
    );
    final productCatalogBloc = _buildCatalogBloc([coffee]);
    addTearDown(() async {
      await cartBloc.close();
      await productCatalogBloc.close();
    });

    await tester.pumpWidget(
      _buildPosShell(
        cartBloc: cartBloc,
        productCatalogBloc: productCatalogBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_fieldWithLabel('Qty'), '3');
    final quantityField = tester.widget<TextField>(_fieldWithLabel('Qty'));
    quantityField.onSubmitted?.call('3');
    await tester.pumpAndSettle();

    expect(cartLocalDataSource.savedCart?.items.single.quantity, 3);
    expect(find.text(r'$10.50'), findsWidgets);
  });

  testWidgets('shows a snackbar when login fails', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final authRepository = _FakeAuthRepository(
      loginError: Exception('login failed'),
    );
    final authBloc = AuthBloc(
      getCurrentUser: GetCurrentUser(authRepository),
      login: Login(authRepository),
      logout: Logout(authRepository),
    );
    addTearDown(() async {
      await authBloc.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    authBloc.add(const AuthStarted());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'seller');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password.'), findsOneWidget);
  });

  testWidgets('shows checkout success screen after completing payment', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final coffee = const Product(
      id: 'p-1',
      name: 'Coffee',
      price: 3.50,
      category: 'Beverages',
    );
    final cartBloc = _buildCartBloc(
      loadedState: PersistedCartState(
        cart: CartEntity(items: [CartItemEntity(product: coffee, quantity: 1)]),
        discount: const CartDiscount.none(),
      ),
    );
    final productCatalogBloc = _buildCatalogBloc([coffee]);
    addTearDown(() async {
      await cartBloc.close();
      await productCatalogBloc.close();
    });

    await tester.pumpWidget(
      _buildPosShell(
        cartBloc: cartBloc,
        productCatalogBloc: productCatalogBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pay Cash'));
    await tester.tap(find.text('Pay Cash'));
    await tester.pumpAndSettle();

    expect(find.text('Checkout Success'), findsOneWidget);
    expect(find.text('Transaction completed'), findsOneWidget);
    expect(find.text('Payment Method: Cash'), findsOneWidget);
    expect(find.text('Back to POS'), findsOneWidget);
  });

  testWidgets('shows a checkout failure snackbar when the total is zero', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final coffee = const Product(
      id: 'p-1',
      name: 'Coffee',
      price: 3.50,
      category: 'Beverages',
    );
    final cartBloc = _buildCartBloc(
      loadedState: PersistedCartState(
        cart: CartEntity(items: [CartItemEntity(product: coffee, quantity: 1)]),
        discount: const CartDiscount.none(),
      ),
    );
    final productCatalogBloc = _buildCatalogBloc([coffee]);
    addTearDown(() async {
      await cartBloc.close();
      await productCatalogBloc.close();
    });

    await tester.pumpWidget(
      _buildPosShell(
        cartBloc: cartBloc,
        productCatalogBloc: productCatalogBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_fieldWithLabel('Discount amount'), '3.50');
    await tester.pumpAndSettle();

    expect(find.text(r'$0.00'), findsWidgets);

    await tester.ensureVisible(find.text('Pay Cash'));
    await tester.tap(find.text('Pay Cash'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to checkout with the current total. Please review the cart.',
      ),
      findsOneWidget,
    );
    expect(find.text('Checkout Success'), findsNothing);
  });
}
