import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korascope/app.dart';

void main() {
  testWidgets('authentication opens the dashboard', (tester) async {
    await tester.pumpWidget(const KoraScopeApp());

    expect(
      find.text('Surveillez vos concurrents.\nAnticipez le marché.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ama@korascope.com',
    );
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Vue d’ensemble'), findsOneWidget);
    expect(find.text('Concurrents'), findsWidgets);
  });
}
