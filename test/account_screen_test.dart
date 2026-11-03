import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexchat/features/auth/account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var requests = 0;
  setUp(() async {
    requests = 0;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co', anonKey: 'test-public-key', debug: false,
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('{"error":"invalid_grant","error_description":"Invalid login credentials"}', 400,
          headers: {'content-type': 'application/json'});
      }),
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(), autoRefreshToken: false, detectSessionInUri: false,
      ),
    );
  });
  tearDown(() async { await Supabase.instance.dispose(); });

  testWidgets('Invalid form stays local without an auth request', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AccountScreen(onDemo: () {})));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('Auth rejection is shown; form allows retry', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AccountScreen(onDemo: () {})));
    await tester.enterText(find.byType(TextFormField).at(0), 'person@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('Small screen with keyboard scrolls to account actions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: AccountScreen(onDemo: () {})));
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
