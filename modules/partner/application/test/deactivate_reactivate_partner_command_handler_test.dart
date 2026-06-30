import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class _RecordingPartnerCommandGateway implements IPartnerCommandGateway {
  BusinessPartner? lastPartner;
  int? lastExpectedVersion;
  String? lastActorId;
  String? lastStatusNote;

  @override
  Future<String> register({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> update({
    required BusinessPartner partner,
    required Set<PartnerRole> roles,
    required bool confirmDuplicate,
    required int expectedVersion,
    required String actorId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> deactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
    String? statusNote,
  }) async {
    lastPartner = partner;
    lastExpectedVersion = expectedVersion;
    lastActorId = actorId;
    lastStatusNote = statusNote;
    return expectedVersion + 1;
  }

  @override
  Future<int> reactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  }) async {
    lastPartner = partner;
    lastExpectedVersion = expectedVersion;
    lastActorId = actorId;
    return expectedVersion + 1;
  }

  @override
  Future<void> delete({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('DeactivatePartnerCommandHandler', () {
    test('deactivates active partner through gateway', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = DeactivatePartnerCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        DeactivatePartnerCommand(
          tenantId: 'tenant-1',
          actorId: 'user-2',
          partnerId: 'partner-1',
          expectedVersion: 2,
          currentStatus: PartnerStatus.active,
          statusNote: 'Tạm ngừng hợp tác',
        ),
      );

      expect(result.businessPartnerId, 'partner-1');
      expect(result.version, 3);
      expect(gateway.lastExpectedVersion, 2);
      expect(gateway.lastActorId, 'user-2');
      expect(gateway.lastStatusNote, 'Tạm ngừng hợp tác');
      expect(gateway.lastPartner?.status, PartnerStatus.inactive);
    });

    test('rejects deactivate when partner is inactive', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = DeactivatePartnerCommandHandler(
        commandGateway: gateway,
      );

      expect(
        () => handler.handle(
          DeactivatePartnerCommand(
            tenantId: 'tenant-1',
            actorId: 'user-2',
            partnerId: 'partner-1',
            expectedVersion: 2,
            currentStatus: PartnerStatus.inactive,
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('ReactivatePartnerCommandHandler', () {
    test('reactivates inactive partner through gateway', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = ReactivatePartnerCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        ReactivatePartnerCommand(
          tenantId: 'tenant-1',
          actorId: 'user-2',
          partnerId: 'partner-1',
          expectedVersion: 3,
          currentStatus: PartnerStatus.inactive,
        ),
      );

      expect(result.businessPartnerId, 'partner-1');
      expect(result.version, 4);
      expect(gateway.lastPartner?.status, PartnerStatus.active);
    });

    test('rejects reactivate when partner is active', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = ReactivatePartnerCommandHandler(
        commandGateway: gateway,
      );

      expect(
        () => handler.handle(
          ReactivatePartnerCommand(
            tenantId: 'tenant-1',
            actorId: 'user-2',
            partnerId: 'partner-1',
            expectedVersion: 2,
            currentStatus: PartnerStatus.active,
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
