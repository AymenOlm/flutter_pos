import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/core/logging/app_bloc_observer.dart';
import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/features/admin/presentation/views/admin_home_view.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_pos/features/auth/presentation/views/login_view.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/features/pos/presentation/views/pos_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPosDependencies();
  Bloc.observer = AppBlocObserver(sl<AppLogger>());
  sl<AppLogger>().info(
    feature: 'app',
    action: 'startup',
    outcome: 'initialized',
  );
  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthStarted()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'POS Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const LoginView();
        }

        if (state.user!.role == UserRole.admin) {
          return const AdminHomeView();
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
            BlocProvider<ProductCatalogBloc>(
              create: (_) =>
                  sl<ProductCatalogBloc>()..add(const LoadProducts()),
            ),
          ],
          child: POSView(
            onLogoutRequested: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        );
      },
    );
  }
}
