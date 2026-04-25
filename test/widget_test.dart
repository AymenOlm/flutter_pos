import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/main.dart';

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
}
