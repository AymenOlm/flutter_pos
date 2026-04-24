import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/features/pos/presentation/views/pos_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPosDependencies();
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
        BlocProvider<ProductCatalogBloc>(
          create: (_) => sl<ProductCatalogBloc>()..add(const LoadProducts()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'POS Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const POSView(),
      ),
    );
  }
}
