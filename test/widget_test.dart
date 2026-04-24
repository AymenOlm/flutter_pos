import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/main.dart';

void main() {
  testWidgets('POS screen renders', (WidgetTester tester) async {
    await initPosDependencies();
    await tester.pumpWidget(const POSApp());
    await tester.pumpAndSettle();

    expect(find.text('POS Console'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
  });
}
