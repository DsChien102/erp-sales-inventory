import 'dart:io';

import 'package:test/test.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';

void main() {
  late String lifecycleSql;
  late String outcomeSql;

  setUpAll(() {
    final root = _findRepoRoot();
    lifecycleSql = File(
      '${root.path}/supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql',
    ).readAsStringSync();
    outcomeSql = File(
      '${root.path}/supabase/migrations/_drafts/001_iam_notify_email_delivery_outcome.sql',
    ).readAsStringSync();
  });

  group('iam email delivery outbox contract', () {
    test('activation/password reset producers emit envelope v1 required keys', () {
      for (final fn in [
        'iam.send_activation_invitation',
        'iam.request_platform_password_reset',
      ]) {
        final start = lifecycleSql.indexOf('function $fn');
        expect(start, greaterThanOrEqualTo(0), reason: fn);
        final end = lifecycleSql.indexOf(r'$$;', start);
        final body = lifecycleSql.substring(start, end);
        expect(body, contains("'event_version', 1"));
        expect(body, contains("'to_email'"));
        expect(body, contains("'correlation_id'"));
        expect(body, contains("'outcome_id'"));
        expect(body, contains("'tenant_id', null"));
        expect(body, isNot(contains("'app_link_url'")));
      }
    });

    test('platform producers use messaging partition uuid, payload tenant_id null', () {
      expect(
        lifecycleSql,
        contains("'00000000-0000-0000-0000-000000000000'::uuid"),
      );
      expect(lifecycleSql, contains("'tenant_id', null"));
    });

    test('queued outcome is recorded in same mutation path', () {
      expect(lifecycleSql, contains('iam.record_email_delivery_outcome'));
      expect(outcomeSql, contains('function iam.record_email_delivery_outcome'));
    });

    test('sample producer payload deserializes via fromPayload', () {
      final payload = <String, dynamic>{
        'event_version': 1,
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'occurred_on': '2026-07-29T10:00:00.000Z',
        'tenant_id': null,
        'template_id': 'activation_invitation',
        'to_email': 'owner@example.com',
        'correlation_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'outcome_id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'locale': 'vi',
        'refs': <String, String>{'user_id': 'dddddddd-dddd-dddd-dddd-dddddddddddd'},
      };

      final event =
          EmailDeliveryRequestedIntegrationEvent.fromPayload(payload);
      expect(event.isPlatformScoped, isTrue);
      expect(event.toEmail, 'owner@example.com');
      expect(event.correlationId, payload['correlation_id']);
      expect(event.outcomeId, payload['outcome_id']);
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
