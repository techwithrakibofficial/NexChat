import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexchat/core/design_system/glass.dart';

void main() {
  testWidgets('Avatar handles an empty display name', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: GlassAvatar(''))));
    expect(find.text('?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Demo entry button is actionable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GlassButton('Explore Demo', onPressed: () => tapped = true))));
    await tester.tap(find.text('Explore Demo'));
    expect(tapped, isTrue);
  });
}
