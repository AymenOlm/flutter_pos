import 'package:get_it/get_it.dart';

import 'package:flutter_pos/features/pos/data/datasources/product_remote_data_source.dart';
import 'package:flutter_pos/features/pos/data/repositories/product_repository_impl.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';

final sl = GetIt.instance;

Future<void> initPosDependencies() async {
  if (!sl.isRegistered<ProductRemoteDataSource>()) {
    sl.registerLazySingleton<ProductRemoteDataSource>(
      MockProductRemoteDataSource.new,
    );
  }

  if (!sl.isRegistered<ProductRepository>()) {
    sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(sl<ProductRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<CalculateTotal>()) {
    sl.registerLazySingleton(CalculateTotal.new);
  }

  if (!sl.isRegistered<CartBloc>()) {
    sl.registerFactory(() => CartBloc(calculateTotal: sl<CalculateTotal>()));
  }

  if (!sl.isRegistered<ProductCatalogBloc>()) {
    sl.registerFactory(
      () => ProductCatalogBloc(repository: sl<ProductRepository>()),
    );
  }
}
