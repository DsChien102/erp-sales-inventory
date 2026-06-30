import '../../ids/business_partner_id.dart';
import '../../value_objects/email_address.dart';
import '../../value_objects/phone_number.dart';
import '../../value_objects/tax_code.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

enum PartnerDuplicateField {
  phone,
  email,
  taxCode,
}

final class PartnerDuplicateMatch {
  const PartnerDuplicateMatch({
    required this.field,
    required this.businessPartnerId,
    required this.displayName,
    required this.matchedValue,
  });

  final PartnerDuplicateField field;
  final BusinessPartnerId businessPartnerId;
  final String displayName;
  final String matchedValue;
}

abstract interface class IPartnerDuplicateChecker {
  Future<List<PartnerDuplicateMatch>> findMatches({
    required TenantId tenantId,
    PhoneNumber? phone,
    EmailAddress? email,
    TaxCode? taxCode,
    BusinessPartnerId? excludePartnerId,
  });
}
