final class CustomerPriceRuleImportParsedRow {
  const CustomerPriceRuleImportParsedRow({
    required this.rowNumber,
    this.ruleId,
    this.customerId,
    this.productReferenceId,
    this.price,
    this.effectiveFrom,
    this.effectiveTo,
    this.note,
  });

  final int rowNumber;
  final String? ruleId;
  final String? customerId;
  final String? productReferenceId;
  final String? price;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String? note;
}

final class CustomerPriceRuleImportParseResult {
  const CustomerPriceRuleImportParseResult._({
    this.rows = const [],
    this.fileErrorCodes = const [],
  });

  const CustomerPriceRuleImportParseResult.parsed(
    List<CustomerPriceRuleImportParsedRow> rows,
  ) : this._(rows: rows);

  CustomerPriceRuleImportParseResult.failed(List<String> fileErrorCodes)
    : this._(fileErrorCodes: fileErrorCodes);

  final List<CustomerPriceRuleImportParsedRow> rows;
  final List<String> fileErrorCodes;

  bool get isParsed => fileErrorCodes.isEmpty;

  List<CustomerPriceRuleImportParsedRow> get unmodifiableRows =>
      List.unmodifiable(rows);

  List<String> get unmodifiableFileErrorCodes =>
      List.unmodifiable(fileErrorCodes);
}
