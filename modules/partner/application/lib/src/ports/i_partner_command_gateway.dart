import 'package:vet45_partner_domain/domain.dart';

abstract interface class IPartnerCommandGateway {
  Future<String> register({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  });

  Future<int> update({
    required BusinessPartner partner,
    required Set<PartnerRole> roles,
    required bool confirmDuplicate,
    required int expectedVersion,
    required String actorId,
  });

  Future<int> deactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
    String? statusNote,
  });

  Future<int> reactivate({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  });

  Future<void> delete({
    required BusinessPartner partner,
    required int expectedVersion,
    required String actorId,
  });
}
