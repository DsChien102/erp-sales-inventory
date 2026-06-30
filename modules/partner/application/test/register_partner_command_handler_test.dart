import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class _RecordingPartnerCommandGateway implements IPartnerCommandGateway {
  BusinessPartner? lastPartner;
  bool? lastConfirmDuplicate;
  String? lastIdempotencyKey;

  @override
  Future<String> register({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  }) async {
    lastPartner = partner;
    lastConfirmDuplicate = confirmDuplicate;
    lastIdempotencyKey = idempotencyKey;
    return 'partner-registered-id';
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
  group('RegisterPartnerCommandHandler', () {
    test('registers partner through gateway and returns result', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = RegisterPartnerCommandHandler(commandGateway: gateway);

      final result = await handler.handle(
        RegisterPartnerCommand(
          id: 'idem-1',
          tenantId: 'tenant-1',
          actorId: 'user-1',
          entityType: EntityType.individual,
          displayName: 'Nguyen Van A',
          individualName: 'Nguyen Van A',
          phone: '0987654321',
          roles: {PartnerRole.customer},
          confirmDuplicate: true,
        ),
      );

      expect(result.businessPartnerId, 'partner-registered-id');
      expect(result.hasTaxCodeWarning, isFalse);
      expect(gateway.lastConfirmDuplicate, isTrue);
      expect(gateway.lastIdempotencyKey, 'idem-1');
      expect(gateway.lastPartner?.displayName.value, 'Nguyen Van A');
      expect(gateway.lastPartner?.status, PartnerStatus.active);
    });

    test('throws when domain invariants fail', () async {
      final handler = RegisterPartnerCommandHandler(
        commandGateway: _RecordingPartnerCommandGateway(),
      );

      expect(
        () => handler.handle(
          RegisterPartnerCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            entityType: EntityType.company,
            displayName: 'Cong ty C',
            phone: '0987654321',
            roles: {PartnerRole.supplier},
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
