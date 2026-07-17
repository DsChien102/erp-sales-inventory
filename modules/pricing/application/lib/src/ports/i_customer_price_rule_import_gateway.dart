import '../customer_price_rule/import/shared/customer_price_rule_import_detail_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_result_dto.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_enums.dart';
import '../customer_price_rule/import/shared/customer_price_rule_import_parse_result.dart';

abstract interface class ICustomerPriceRuleImportGateway {
  Future<CustomerPriceRuleImportDetailDto> create({
    required String tenantId,
    required String templateVersion,
    required String originalFileName,
    required CustomerPriceRuleImportMode importMode,
    required CustomerPriceRuleImportParseResult parseResult,
  });

  Future<CustomerPriceRuleImportDetailDto> get({
    required String tenantId,
    required String importId,
    required CustomerPriceRuleImportRowStatus? rowStatus,
    required String? cursor,
    required int limit,
  });

  Future<CustomerPriceRuleImportResultDto> confirm({
    required String tenantId,
    required String importId,
    required int expectedVersion,
    required DateTime businessDate,
    required bool acknowledgeWarningRows,
  });

  Future<CustomerPriceRuleImportDto> cancel({
    required String tenantId,
    required String importId,
    required int expectedVersion,
  });
}
