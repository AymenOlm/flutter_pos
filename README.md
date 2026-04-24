# Flutter POS

Production-oriented Point of Sale application built with Flutter, Clean Architecture, and the BLoC pattern.

## Overview

This project is focused on a scalable POS core with clear architecture boundaries:

- Domain-first business logic
- Reactive state management with flutter_bloc
- Dependency injection with get_it
- Value equality with equatable

Current implemented flow:

- Product catalog loading from a mock remote data source
- Product search in the catalog
- Reactive shopping cart updates
- 10% tax total calculation
- Checkout actions for cash and card

## Tech Stack

- Flutter (Material 3)
- flutter_bloc
- equatable
- get_it

## Project Structure

The POS feature follows this module structure:

lib/features/pos/

- data/
	- datasources/
		- product_remote_data_source.dart
	- models/
		- product_model.dart
	- repositories/
		- product_repository_impl.dart
- domain/
	- entities/
		- product.dart
		- cart_entity.dart
	- repositories/
		- product_repository.dart
	- usecases/
		- calculate_total.dart
- presentation/
	- bloc/
		- cart/
			- cart_event.dart
			- cart_state.dart
			- cart_bloc.dart
		- product_catalog/
			- product_catalog_event.dart
			- product_catalog_state.dart
			- product_catalog_bloc.dart
	- di/
		- service_locator.dart
	- views/
		- pos_view.dart

Entrypoint:

- lib/main.dart

## Architecture Notes

### Data Layer

- ProductModel extends the Product entity
- MockProductRemoteDataSource simulates remote product fetch
- ProductRepositoryImpl maps datasource results to domain contracts

### Domain Layer

- Entities: Product, CartItemEntity, CartEntity
- Use case: CalculateTotal
	- Standard tax rate: 10%
	- Totals exposed as subtotal, tax, total

### Presentation Layer

- CartBloc events:
	- AddItem
	- RemoveItem
	- ClearCart
- ProductCatalogBloc:
	- Loads products
	- Filters by search query
- POSView:
	- Responsive two-panel layout
	- Left: product grid and search
	- Right: cart list, totals, checkout actions

## Getting Started

Prerequisites:

- Flutter SDK installed and available in PATH

Install dependencies:

flutter pub get

Run app:

flutter run

## Development Commands

Analyze code:

flutter analyze

Run tests:

flutter test

## Current Status and Planning

Development progress, next features, and bug backlog are tracked in:

- PROJECT_TRACKER.md

## Suggested Next Steps

- Add unit tests for domain use cases and repository logic
- Add CartBloc transition tests
- Add stronger checkout flow validation and receipt generation
- Introduce persistent local storage for cart and order history

## License

Internal project. Add a license section when publishing externally.
