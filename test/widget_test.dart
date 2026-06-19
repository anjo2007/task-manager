import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide/main.dart';
import 'package:tide/providers/task_provider.dart';

void main() {
  testWidgets('Smoke test - Tide app loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => TaskProvider(),
        child: const TideApp(),
      ),
    );

    // Allow animations to complete to clean up pending timers (e.g. flutter_animate)
    await tester.pumpAndSettle();

    // Verify that our TideApp loads
    expect(find.byType(TideApp), findsOneWidget);
  });
}
