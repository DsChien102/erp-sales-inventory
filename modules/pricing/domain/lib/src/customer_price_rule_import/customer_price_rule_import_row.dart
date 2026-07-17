import 'customer_price_rule_import_row_status.dart';

final class CustomerPriceRuleImportRow {
  CustomerPriceRuleImportRow({
    required this.id,
    required this.rowNumber,
    CustomerPriceRuleImportRowStatus status =
        CustomerPriceRuleImportRowStatus.parsed,
  }) : _status = status;

  final String id;
  final int rowNumber;

  CustomerPriceRuleImportRowStatus _status;
  CustomerPriceRuleImportRowStatus get status => _status;

  void markValid() => _transition(
    from: const {CustomerPriceRuleImportRowStatus.parsed},
    to: CustomerPriceRuleImportRowStatus.valid,
  );

  void markWarning() => _transition(
    from: const {CustomerPriceRuleImportRowStatus.parsed},
    to: CustomerPriceRuleImportRowStatus.warning,
  );

  void markError() => _transition(
    from: const {CustomerPriceRuleImportRowStatus.parsed},
    to: CustomerPriceRuleImportRowStatus.error,
  );

  void markImported() => _transition(
    from: const {
      CustomerPriceRuleImportRowStatus.valid,
      CustomerPriceRuleImportRowStatus.warning,
    },
    to: CustomerPriceRuleImportRowStatus.imported,
  );

  void markSkipped() => _transition(
    from: const {CustomerPriceRuleImportRowStatus.error},
    to: CustomerPriceRuleImportRowStatus.skipped,
  );

  void markFailed() => _transition(
    from: const {
      CustomerPriceRuleImportRowStatus.valid,
      CustomerPriceRuleImportRowStatus.warning,
    },
    to: CustomerPriceRuleImportRowStatus.failed,
  );

  void _transition({
    required Set<CustomerPriceRuleImportRowStatus> from,
    required CustomerPriceRuleImportRowStatus to,
  }) {
    if (!from.contains(_status)) {
      throw StateError('Cannot transition row from $_status to $to');
    }
    _status = to;
  }
}
