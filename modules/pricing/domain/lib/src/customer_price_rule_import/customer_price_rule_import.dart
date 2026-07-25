import 'customer_price_rule_import_mode.dart';
import 'customer_price_rule_import_row.dart';
import 'customer_price_rule_import_row_status.dart';
import 'customer_price_rule_import_status.dart';

final class CustomerPriceRuleImport {
  CustomerPriceRuleImport({
    required this.id,
    required this.mode,
    int version = 1,
    List<CustomerPriceRuleImportRow> rows = const [],
  }) : _version = version,
       _rows = List.of(rows) {
    if (version <= 0) {
      throw ArgumentError.value(version, 'version', 'must be positive');
    }
  }

  final String id;
  final CustomerPriceRuleImportMode mode;
  int _version;
  int get version => _version;

  CustomerPriceRuleImportStatus _status =
      CustomerPriceRuleImportStatus.uploaded;
  CustomerPriceRuleImportStatus get status => _status;

  final List<CustomerPriceRuleImportRow> _rows;
  List<CustomerPriceRuleImportRow> get rows => List.unmodifiable(_rows);

  void startValidating() => _transition(
    from: const {CustomerPriceRuleImportStatus.uploaded},
    to: CustomerPriceRuleImportStatus.validating,
  );

  void markReadyToImport() => _transition(
    from: const {CustomerPriceRuleImportStatus.validating},
    to: CustomerPriceRuleImportStatus.readyToImport,
  );

  void markImporting() => _transition(
    from: const {CustomerPriceRuleImportStatus.readyToImport},
    to: CustomerPriceRuleImportStatus.importing,
  );

  void fail() {
    if (_status != CustomerPriceRuleImportStatus.uploaded &&
        _status != CustomerPriceRuleImportStatus.validating) {
      throw StateError('Cannot fail from status $_status');
    }
    _status = CustomerPriceRuleImportStatus.failed;
    _version += 1;
  }

  void cancel() {
    if (_status != CustomerPriceRuleImportStatus.uploaded &&
        _status != CustomerPriceRuleImportStatus.readyToImport) {
      throw StateError('Cannot cancel from status $_status');
    }
    _status = CustomerPriceRuleImportStatus.canceled;
    _version += 1;
  }

  void complete() {
    if (_status != CustomerPriceRuleImportStatus.importing) {
      throw StateError('Cannot complete from status $_status');
    }
    final failed = _rows
        .where((row) => row.status == CustomerPriceRuleImportRowStatus.failed)
        .length;
    final skipped = _rows
        .where((row) => row.status == CustomerPriceRuleImportRowStatus.skipped)
        .length;
    _status = failed == 0 && skipped == 0
        ? CustomerPriceRuleImportStatus.completed
        : CustomerPriceRuleImportStatus.completedWithErrors;
    _version += 1;
  }

  int get totalRows => _rows.length;
  int get validRows => _rows
      .where(
        (row) =>
            row.status == CustomerPriceRuleImportRowStatus.valid ||
            row.status == CustomerPriceRuleImportRowStatus.warning,
      )
      .length;
  int get warningRows => _rows
      .where((row) => row.status == CustomerPriceRuleImportRowStatus.warning)
      .length;
  int get errorRows => _rows
      .where((row) => row.status == CustomerPriceRuleImportRowStatus.error)
      .length;
  int get importedRows => _rows
      .where((row) => row.status == CustomerPriceRuleImportRowStatus.imported)
      .length;
  int get skippedRows => _rows
      .where((row) => row.status == CustomerPriceRuleImportRowStatus.skipped)
      .length;
  int get failedRows => _rows
      .where((row) => row.status == CustomerPriceRuleImportRowStatus.failed)
      .length;

  void _transition({
    required Set<CustomerPriceRuleImportStatus> from,
    required CustomerPriceRuleImportStatus to,
  }) {
    if (!from.contains(_status)) {
      throw StateError('Cannot transition from $_status to $to');
    }
    _status = to;
    _version += 1;
  }
}
