import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../legal_entity_type.dart';

/// Tax code must be 10–13 digits after stripping non-digit characters,
/// for every legal entity type (IAM refactor bảng 2 ④).
final class TaxCodeFormatRule implements IBusinessRule {
  TaxCodeFormatRule({
    required this.entityType,
    required String taxCode,
  }) : _taxCode = normalize(taxCode);

  static const int minLength = 10;
  static const int maxLength = 13;

  /// Removes every non-digit character (`0101234567-001` → `0101234567001`).
  static String normalize(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  final LegalEntityType entityType;
  final String _taxCode;

  @override
  bool isBroken() =>
      _taxCode.length < minLength || _taxCode.length > maxLength;

  @override
  String get message => 'Mã số thuế phải gồm 10–13 chữ số.';
}
