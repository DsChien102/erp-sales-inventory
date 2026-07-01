import 'package:test/test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class _RecordingPartnerCommandGateway implements IPartnerCommandGateway {
  BusinessPartner? lastPartner;
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
  }) async {
    lastPartner = partner;
    lastExpectedVersion = expectedVersion;
    lastActorId = actorId;
  }
}

void main() {
  group('DeletePartnerCommandHandler', () {
    test('scn_e02_u02_fr04_01 deletes partner through gateway', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = DeletePartnerCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        DeletePartnerCommand(
          tenantId: 'tenant-1',
          actorId: 'user-2',
          partnerId: 'partner-1',
          expectedVersion: 2,
          hasBusinessData: false,
        ),
      );

      expect(result.businessPartnerId, 'partner-1');
      expect(gateway.lastExpectedVersion, 2);
      expect(gateway.lastActorId, 'user-2');
      expect(gateway.lastPartner, isNotNull);
      expect(gateway.lastPartner!.domainEvents, hasLength(1));
    });

    test('scn_e02_u02_fr02_01 rejects when partner has business data', () async {
      final gateway = _RecordingPartnerCommandGateway();
      final handler = DeletePartnerCommandHandler(
        commandGateway: gateway,
      );

      expect(
        () => handler.handle(
          DeletePartnerCommand(
            tenantId: 'tenant-1',
            actorId: 'user-2',
            partnerId: 'partner-1',
            expectedVersion: 2,
            hasBusinessData: true,
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );

      expect(gateway.lastPartner, isNull);
    });
  });
}
