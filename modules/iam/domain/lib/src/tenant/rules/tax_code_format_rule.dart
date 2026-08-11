import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../legal_entity_type.dart';

/// Validates tax code digits for the given legal entity type.
final class TaxCodeFormatRule implements IBusinessRule {
  TaxCodeFormatRule({
    required this.entityType,
    required String taxCode,
  }) : _taxCode = taxCode.replaceAll(RegExp(r'\D'), '');

  final LegalEntityType entityType;
  final String _taxCode;

  @override
  bool isBroken() {
    if (_taxCode.isEmpty || !RegExp(r'^\d+$').hasMatch(_taxCode)) {
      return true;
    }
    final expectedLength = switch (entityType) {
      LegalEntityType.enterprise => 10,
      LegalEntityType.householdBusiness => 12,
    };
    return _taxCode.length != expectedLength;
  }

  @override
  String get message => 'Tax code format is invalid for legal entity type';
}
