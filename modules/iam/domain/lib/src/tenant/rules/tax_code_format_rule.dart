import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../legal_entity_type.dart';

/// Tax code must be 10 digits, 12 digits, or the branch form `10 digits-3 digits`
/// (`0123456789-001`), for every legal entity type. The dash is kept: MISA and
/// the tax authority identify branches by the dashed form.
final class TaxCodeFormatRule implements IBusinessRule {
  TaxCodeFormatRule({
    required this.entityType,
    required String taxCode,
  }) : _taxCode = normalize(taxCode);

  static final RegExp _format = RegExp(r'^(\d{10}|\d{12}|\d{10}-\d{3})$');

  /// Trims surrounding whitespace only (`' 0101234567-001 '` → `0101234567-001`).
  static String normalize(String raw) => raw.trim();

  final LegalEntityType entityType;
  final String _taxCode;

  @override
  bool isBroken() => !_format.hasMatch(_taxCode);

  @override
  String get message =>
      'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).';
}
