import 'package:get_it/get_it.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/core/utils/receipt_service.dart';
import 'package:flutter_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';
import 'package:flutter_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';
import 'package:flutter_pos/features/pos/data/datasources/product_local_data_source.dart';
import 'package:flutter_pos/features/pos/data/datasources/product_remote_data_source.dart';
import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/data/repositories/product_repository_impl.dart';
import 'package:flutter_pos/features/pos/data/repositories/sales_repository_impl.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';

final sl = GetIt.instance;

Future<void> initPosDependencies() async {
  if (!sl.isRegistered<AppLogSink>()) {
    sl.registerLazySingleton<AppLogSink>(ConsoleAppLogSink.new);
  }

  if (!sl.isRegistered<BufferedAppLogSink>()) {
    sl.registerLazySingleton(BufferedAppLogSink.new);
  }

  if (!sl.isRegistered<AppLogger>()) {
    sl.registerLazySingleton<AppLogger>(
      () => AppLogger(
        sinks: <AppLogSink>[sl<AppLogSink>(), sl<BufferedAppLogSink>()],
      ),
    );
  }

  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      SharedPrefsAuthLocalDataSource.new,
    );
  }

  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<GetCurrentUser>()) {
    sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  }

  if (!sl.isRegistered<Login>()) {
    sl.registerLazySingleton(() => Login(sl<AuthRepository>()));
  }

  if (!sl.isRegistered<Logout>()) {
    sl.registerLazySingleton(() => Logout(sl<AuthRepository>()));
  }

  if (!sl.isRegistered<PosLocalDatabase>()) {
    sl.registerLazySingleton(PosLocalDatabase.new);
  }

  if (!sl.isRegistered<ProductRemoteDataSource>()) {
    sl.registerLazySingleton<ProductRemoteDataSource>(
      MockProductRemoteDataSource.new,
    );
  }

  if (!sl.isRegistered<ProductLocalDataSource>()) {
    sl.registerLazySingleton<ProductLocalDataSource>(
      () => DriftProductLocalDataSource(sl<PosLocalDatabase>()),
    );
  }

  if (!sl.isRegistered<SalesLocalDataSource>()) {
    sl.registerLazySingleton<SalesLocalDataSource>(
      () => DriftSalesLocalDataSource(sl<PosLocalDatabase>()),
    );
  }

  if (!sl.isRegistered<ProductRepository>()) {
    sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        remoteDataSource: sl<ProductRemoteDataSource>(),
        localDataSource: sl<ProductLocalDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<SalesRepository>()) {
    sl.registerLazySingleton<SalesRepository>(
      () => SalesRepositoryImpl(sl<SalesLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<CalculateTotal>()) {
    sl.registerLazySingleton(CalculateTotal.new);
  }

  if (!sl.isRegistered<SaveTransaction>()) {
    sl.registerLazySingleton(() => SaveTransaction(sl<SalesRepository>()));
  }

  if (!sl.isRegistered<ReceiptService>()) {
    sl.registerLazySingleton(ReceiptService.new);
  }

  if (!sl.isRegistered<CartBloc>()) {
    sl.registerFactory(
      () => CartBloc(
        calculateTotal: sl<CalculateTotal>(),
        saveTransaction: sl<SaveTransaction>(),
        logger: sl<AppLogger>(),
      ),
    );
  }

  if (!sl.isRegistered<ProductCatalogBloc>()) {
    sl.registerFactory(
      () => ProductCatalogBloc(
        repository: sl<ProductRepository>(),
        logger: sl<AppLogger>(),
      ),
    );
  }

  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(
      () => AuthBloc(
        getCurrentUser: sl<GetCurrentUser>(),
        login: sl<Login>(),
        logout: sl<Logout>(),
      ),
    );
  }
}
