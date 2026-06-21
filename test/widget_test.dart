import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurix/app/app.dart';

void main() {
  testWidgets('shows app shell with dashboard placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RestaurixApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Admin'), findsOneWidget);
  });
}
