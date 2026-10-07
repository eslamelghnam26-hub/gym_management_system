import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_management_system/app/app.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to splash screen', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const GymApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Flush the splash timer so no pending timers remain.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  });
}