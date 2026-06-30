import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class _RecordingPartnerCommandGateway implements IPartnerCommandGateway {
  BusinessPartner? lastPartner;
  Set<PartnerRole>? lastRoles;
  bool? lastConfirmDuplicate;
  int? lastExpectedVersion;
  String? lastActorId;

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
  }) async {
    lastPartner = partner;
    lastRoles = roles;
    lastConfirmDuplicate = confirmDuplicate;
    lastExpectedVersion = expectedVersion;
    lastActorId = actorId;
    return expectedVersion + 1;
  }

  @override
  Future<int> deactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
    String? statusNote,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> reactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  }) {
    throw UnimplementedError();
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
  group('UpdatePartnerProfileCommandHandler', () {
    test('updates partner through gateway and returns result', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = UpdatePartnerProfileCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        UpdatePartnerProfileCommand(
          tenantId: 'tenant-1',
          actorId: 'user-2',
          partnerId: 'partner-1',
          expectedVersion: 2,
          entityType: EntityType.individual,
          displayName: 'Nguyen Van B',
          individualName: 'Nguyen Van B',
          phone: '0912345678',
          roles: {PartnerRole.customer, PartnerRole.supplier},
          currentStatus: PartnerStatus.active,
          confirmDuplicate: true,
        ),
      );

      expect(result.businessPartnerId, 'partner-1');
      expect(result.version, 3);
      expect(gateway.lastConfirmDuplicate, isTrue);
      expect(gateway.lastExpectedVersion, 2);
      expect(gateway.lastActorId, 'user-2');
      expect(gateway.lastPartner?.displayName.value, 'Nguyen Van B');
    });
  });
}
