import '../../shared/cursor_page_dto.dart';
import 'customer_price_rule_import_dto.dart';
import 'customer_price_rule_import_row_preview_dto.dart';

final class CustomerPriceRuleImportDetailDto {
  const CustomerPriceRuleImportDetailDto({
    required this.batch,
    required this.rows,
  });

  final CustomerPriceRuleImportDto batch;
  final CursorPageDto<CustomerPriceRuleImportRowPreviewDto> rows;
}
