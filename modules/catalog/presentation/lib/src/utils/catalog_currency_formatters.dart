import 'package:vet45_design_system/design_system.dart';

/// Formats catalog money amount only — round to nearest đồng, thousand separators (`.`).
/// Example: `115.000`
String? formatCatalogCurrencyAmount(num? value) {
  if (value == null) return null;
  return VMoneyValidator.format(value.round());
}

/// Formats catalog money for display — round to nearest đồng, thousand separators.
/// Matches Product Control Center / detail price labels (e.g. `115.000 đ`).
String formatCatalogCurrency(double? value) {
  final amount = formatCatalogCurrencyAmount(value);
  if (amount == null) return '--';
  return '$amount đ';
}

/// Parses a money display/input string (accepts `.` and `,` thousand separators).
int? parseCatalogCurrencyAmount(String text) => VMoneyValidator.parse(text);
