import 'package:vet45_partner_domain/domain.dart';

abstract interface class IPartnerCommandGateway {
  Future<String> register({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  });
}
