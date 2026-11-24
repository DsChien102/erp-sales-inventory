import 'package:c45_design_system/design_system.dart';

String formatCatalogCurrency(num? value) {
  if (value == null) return '--';
  return '${VMoneyValidator.format(value.round())} đ';
}
