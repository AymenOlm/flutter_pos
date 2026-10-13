<div align="center">

# 🛒 Flutter POS (Point of Sale)

A robust, production-oriented Point of Sale application showcasing modern Flutter development practices. Built with Clean Architecture, BLoC state management, and a Domain-Driven Design approach.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-brightgreen)]()
[![State Management](https://img.shields.io/badge/State-BLoC-blue)]()
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)]()

_A perfect reference project for building scalable, offline-first Flutter applications._

</div>

---

## 📸 Previews

> **Note:** Replace these placeholder links with actual screenshots of your application!

<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=POS+Dashboard" alt="POS Dashboard" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Cart+View" alt="Cart View" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=Admin+Panel" alt="Admin Panel" width="250"/>
</div>

---

## ✨ Features

- **Offline-First Data:** Uses `drift` (SQLite) for local persistence of products and sales.
- **Reactive State:** Seamless UI updates driven by `flutter_bloc`.
- **Domain-Driven Business Logic:** Highly decoupled architecture making business rules easy to test and maintain.
- **Cart Management:** Dynamic shopping cart with standard 10% tax total calculations.
- **Admin Console:** Easily add, edit, or delete products and review sales transaction history.
- **Secure Storage:** Implementation of `flutter_secure_storage` and `cryptography` for secure data handling.
- **Receipt Generation (WIP):** Setup included for PDF creation and printing using the `pdf` and `printing` packages.
- **Responsive Design:** Two-panel layout supporting various screen sizes.

---

## 🏗️ Architecture

This project strictly adheres to **Clean Architecture** principles, dividing the system into three main layers to ensure separation of concerns, scalability, and testability:

### 1. Presentation Layer
- **State Management:** Handled by `flutter_bloc` (e.g., `CartBloc`, `ProductCatalogBloc`).
- **UI Views:** Built with Material 3. Examples include `POSView` and `AdminHomeView`.

### 2. Domain Layer
The core of the application containing business logic, entirely independent of other layers.
- **Entities:** `Product`, `CartEntity`, `TransactionRecord`.
- **Use Cases:** `CalculateTotal`, `SaveTransaction`.
- **Contracts (Repositories):** `ProductRepository`, `SalesRepository`.

### 3. Data Layer
Handles data retrieval and persistence, implementing the domain repository contracts.
- **Data Sources:** `ProductLocalDataSource` (Drift), `MockProductRemoteDataSource`.
- **Models:** `ProductModel`.

### Dependency Injection
All services, blocs, and repositories are managed and injected using `get_it`.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Material 3)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Dependency Injection:** [get_it](https://pub.dev/packages/get_it)
- **Local Database:** [drift](https://pub.dev/packages/drift)
- **Value Equality:** [equatable](https://pub.dev/packages/equatable)
- **Functional Programming:** [dartz](https://pub.dev/packages/dartz)
- **Security:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), [cryptography](https://pub.dev/packages/cryptography)
- **PDF & Printing:** [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your PATH.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/flutter_pos.git
   cd flutter_pos
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🧑‍💻 Development Commands

Keep the code clean and well-tested using the following commands:

- **Analyze code (Linting):**
  ```bash
  flutter analyze
  ```

- **Run unit tests:**
  ```bash
  flutter test
  ```

---

## 🗺️ Roadmap & Next Steps

We are constantly working to improve this POS system. Here is what's on the horizon:

- [ ] **Testing:** Add comprehensive unit tests for domain use cases, repository logic, and `CartBloc` transitions.
- [ ] **Checkout Validation:** Implement stronger validation rules during the checkout flow.
- [ ] **Receipt Generation:** Finalize and polish PDF receipt generation and printing functionality.
- [ ] **Persistent Cart:** Introduce local storage caching to restore the cart state on app restart.
- [ ] **Reporting:** Advanced sales charts and reporting in the Admin dashboard.

_Development progress, next features, and bug backlogs are tracked in `PROJECT_TRACKER.md`._

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! This is an open-source project and I would love to see how the community can help improve it.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. (Note: Please ensure a LICENSE file is added to the repository).
