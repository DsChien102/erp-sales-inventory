import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_integration_events/integration_events.dart';

class _FakePreferencePort implements IPlatformUserPreferencePort {
  String? _lastSelected = 'tenant-active';

  String? get lastSelected => _lastSelected;

  @override
  Future<String?> getLastSelectedTenantId() async => _lastSelected;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    _lastSelected = tenantId;
  }
}

void main() {
  group('MembershipDeactivatedIntegrationEventHandler', () {
    late _FakePreferencePort preferencePort;
    late MembershipDeactivatedIntegrationEventHandler handler;

    setUp(() {
      preferencePort = _FakePreferencePort();
      handler = MembershipDeactivatedIntegrationEventHandler(
        preferencePort: preferencePort,
      );
    });

    test('clears last_selected_tenant when member is deactivated', () async {
      expect(preferencePort.lastSelected, 'tenant-active');

      final event = MembershipDeactivatedIntegrationEvent(
        id: 'evt-001',
        occurredOn: DateTime.now().toUtc(),
        tenantId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        membershipId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        version: 2,
        actorUserId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      );

      await handler.handle(event);

      expect(preferencePort.lastSelected, isNull);
    });

    test('clears preference even when last_selected is already null', () async {
      preferencePort = _FakePreferencePort();
      await preferencePort.setLastSelectedTenantId(null);
      handler = MembershipDeactivatedIntegrationEventHandler(
        preferencePort: preferencePort,
      );

      final event = MembershipDeactivatedIntegrationEvent(
        id: 'evt-002',
        occurredOn: DateTime.now().toUtc(),
        tenantId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        membershipId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        version: 1,
        actorUserId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      );

      await handler.handle(event);

      expect(preferencePort.lastSelected, isNull);
    });
  });

  group('MembershipDeactivatedIntegrationEvent serialization', () {
    test('fromPayload round-trips toPayload correctly', () {
      final event = MembershipDeactivatedIntegrationEvent(
        id: 'evt-rt-01',
        occurredOn: DateTime.utc(2026, 8, 19, 10),
        tenantId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        membershipId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        version: 3,
        actorUserId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      );

      final payload = event.toPayload();
      final restored =
          MembershipDeactivatedIntegrationEvent.fromPayload(payload);

      expect(restored.id, event.id);
      expect(restored.tenantId, event.tenantId);
      expect(restored.membershipId, event.membershipId);
      expect(restored.userId, event.userId);
      expect(restored.version, event.version);
      expect(restored.actorUserId, event.actorUserId);
      expect(restored.eventType, MembershipDeactivatedIntegrationEvent.type);
    });

    test('fromPayload rejects missing user_id', () {
      expect(
        () => MembershipDeactivatedIntegrationEvent.fromPayload({
          'event_version': 1,
          'id': 'x',
          'tenant_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'membership_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          // user_id missing
          'actor_user_id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          'version': 1,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromPayload rejects unsupported event_version', () {
      expect(
        () => MembershipDeactivatedIntegrationEvent.fromPayload({
          'event_version': 99,
          'id': 'x',
          'tenant_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'membership_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'user_id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
          'actor_user_id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          'version': 1,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
