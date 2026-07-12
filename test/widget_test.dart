import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:korascope/app.dart';
import 'package:korascope/core/network/api_client.dart';
import 'package:korascope/features/auth/auth.service.dart';
import 'package:korascope/features/competitors/competitors.service.dart';
import 'package:korascope/features/reports/reports.service.dart';

class MemorySessionStore implements SessionStore {
  String? value;
  String? lastValidationDay;

  @override
  Future<void> clearSecretKey() async => value = null;

  @override
  Future<void> clearLastValidationDay() async => lastValidationDay = null;

  @override
  Future<String?> readSecretKey() async => value;

  @override
  Future<String?> readLastValidationDay() async => lastValidationDay;

  @override
  Future<void> writeSecretKey(String value) async => this.value = value;

  @override
  Future<void> writeLastValidationDay(String value) async =>
      lastValidationDay = value;
}

void main() {
  test('report html content is converted to readable plain text', () {
    final report = WatchReport.fromJson({
      'id': 'report-1',
      'name': 'Rapport HTML',
      'date': '2026-06-25',
      'contenu':
          '<h1>Analyse &amp; veille</h1><p>Hausse SEO&nbsp;importante.</p><ul><li>Signal A</li></ul>',
      'utilisateurId': 'user-1',
    });

    expect(report.plainTextContent, contains('Analyse & veille'));
    expect(report.plainTextContent, contains('Hausse SEO importante.'));
    expect(report.plainTextContent, contains('• Signal A'));
    expect(report.plainTextContent, isNot(contains('<h1>')));
    expect(report.summary, isNot(contains('<p>')));
  });

  test('competitor discovery request sends user context to n8n', () async {
    Map<String, dynamic>? payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    });
    final apiClient = ApiClient(client: client)..secretKey = 'secret-test';
    final service = CompetitorsService(apiClient: apiClient);

    await service.requestDiscovery(
      userId: 'user-1',
      email: 'ama@korascope.com',
      interests: ['Finance', 'Technologie'],
    );

    expect(payload, {
      'userId': 'user-1',
      'email': 'ama@korascope.com',
      'interests': ['Finance', 'Technologie'],
      'secretKey': 'secret-test',
      'action': 'search_new_competitor',
    });
  });

  test('stored session is cleared when validation returns invalid status', () async {
    final store = MemorySessionStore()..value = 'stale-token';
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/validate')) {
        return http.Response(
          jsonEncode({'status': 'INVALID', 'message': 'Session invalide'}),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    final auth = AuthService(
      apiClient: ApiClient(client: client),
      sessionStore: store,
    );

    await auth.initialize();

    expect(auth.isAuthenticated, isFalse);
    expect(await store.readSecretKey(), isNull);
  });

  testWidgets('OTP authentication opens the dashboard', (tester) async {
    var profileWebhookCallCount = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/request-otp')) {
        return http.Response('{}', 200);
      }
      if (request.url.path.endsWith('/verify-otp')) {
        return http.Response(
          jsonEncode({'token': 'secret-test', 'isNew': false}),
          200,
        );
      }
      if (request.url.path.endsWith('/utilisateurs/me')) {
        return http.Response(
          jsonEncode({
            'id': 'user-1',
            'fullName': 'Ama Koffi',
            'email': 'ama@korascope.com',
            'profileUrl': null,
            'accountType': 'STANDARD',
            'interestDomains': <Object>[],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/interest-domains')) {
        return http.Response('[]', 200);
      }
      if (request.method == 'PUT' &&
          request.url.path.endsWith('/utilisateurs/user-1')) {
        return http.Response('{}', 200);
      }
      if (request.url.host == 'n8n.adaptimate.org') {
        profileWebhookCallCount++;
        return http.Response('{}', 200);
      }
      return http.Response('{}', 404);
    });
    final auth = AuthService(
      apiClient: ApiClient(client: client),
      sessionStore: MemorySessionStore(),
    );
    await tester.pumpWidget(KoraScopeApp(authService: auth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth_email')),
      'ama@korascope.com',
    );
    await tester.ensureVisible(find.byKey(const Key('auth_submit')));
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_otp')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('auth_otp')), '123456');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Vue d’ensemble'), findsOneWidget);

    await tester.tap(find.text('Compte').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modifier le profil'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le profil'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nom complet'),
      'Ama Mensah',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier le profil'), findsNothing);
    expect(profileWebhookCallCount, 0);
    expect(tester.takeException(), isNull);
  });
}
