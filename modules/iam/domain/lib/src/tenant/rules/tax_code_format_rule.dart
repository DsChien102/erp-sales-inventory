import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../legal_entity_type.dart';

/// Validates tax code digits for the given legal entity type.
/// Supports 10 to 13 digits (or standard branch format `0123456789-001`).
final class TaxCodeFormatRule implements IBusinessRule {
  TaxCodeFormatRule({
    required this.entityType,
    required String taxCode,
  }) : _taxCode = taxCode.trim();

  final LegalEntityType entityType;
  final String _taxCode;

  @override
  bool isBroken() {
    return !RegExp(r'^(\d{10,13}|\d{10}-\d{3})$').hasMatch(_taxCode);
  }

  @override
  String get message =>
      'Mã số thuế phải từ 10 đến 13 chữ số (hoặc định dạng 10 số - 3 số chi nhánh).';
}
