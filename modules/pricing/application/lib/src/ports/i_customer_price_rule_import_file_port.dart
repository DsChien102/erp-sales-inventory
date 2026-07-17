import 'dart:typed_data';

import '../customer_price_rule/import/shared/customer_price_rule_import_template_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_parse_result.dart';

abstract interface class ICustomerPriceRuleImportFilePort {
  CustomerPriceRuleImportTemplateDto createTemplateV1();

  CustomerPriceRuleImportParseResult parse({
    required String templateVersion,
    required String originalFileName,
    required Uint8List bytes,
  });
}
