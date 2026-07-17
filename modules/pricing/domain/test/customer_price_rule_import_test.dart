import 'package:test/test.dart';
import 'package:vet45_pricing_domain/domain.dart';

void main() {
  test('batch lifecycle transitions to terminal status', () {
    final batch = CustomerPriceRuleImport(
      id: 'import-1',
      mode: CustomerPriceRuleImportMode.upsert,
      rows: [
        CustomerPriceRuleImportRow(id: 'r1', rowNumber: 2)
          ..markValid()
          ..markImported(),
      ],
    );

    batch.startValidating();
    batch.markReadyToImport();
    batch.markImporting();
    batch.complete();

    expect(batch.status, CustomerPriceRuleImportStatus.completed);
    expect(batch.importedRows, 1);
  });

  test('failed/skipped rows produce completedWithErrors', () {
    final row1 = CustomerPriceRuleImportRow(id: 'r1', rowNumber: 2)
      ..markValid()
      ..markFailed();
    final row2 = CustomerPriceRuleImportRow(id: 'r2', rowNumber: 3)
      ..markError()
      ..markSkipped();
    final batch = CustomerPriceRuleImport(
      id: 'import-1',
      mode: CustomerPriceRuleImportMode.upsert,
      rows: [row1, row2],
    );

    batch.startValidating();
    batch.markReadyToImport();
    batch.markImporting();
    batch.complete();

    expect(batch.status, CustomerPriceRuleImportStatus.completedWithErrors);
    expect(batch.failedRows, 1);
    expect(batch.skippedRows, 1);
  });

  test('cancel allowed only from uploaded/ready', () {
    final uploaded = CustomerPriceRuleImport(
      id: 'import-1',
      mode: CustomerPriceRuleImportMode.upsert,
    );
    uploaded.cancel();
    expect(uploaded.status, CustomerPriceRuleImportStatus.canceled);

    final importing =
        CustomerPriceRuleImport(
            id: 'import-2',
            mode: CustomerPriceRuleImportMode.upsert,
          )
          ..startValidating()
          ..markReadyToImport()
          ..markImporting();
    expect(importing.cancel, throwsStateError);
  });

  test('batch rejects transitions that skip lifecycle stages', () {
    final batch = CustomerPriceRuleImport(
      id: 'import-1',
      mode: CustomerPriceRuleImportMode.upsert,
    );

    expect(batch.markReadyToImport, throwsStateError);
    expect(batch.markImporting, throwsStateError);

    batch.startValidating();
    expect(batch.startValidating, throwsStateError);
    expect(batch.markImporting, throwsStateError);
  });

  test('batch terminal statuses are immutable', () {
    final batch = CustomerPriceRuleImport(
      id: 'import-1',
      mode: CustomerPriceRuleImportMode.upsert,
    )..cancel();

    expect(batch.startValidating, throwsStateError);
    expect(batch.markReadyToImport, throwsStateError);
    expect(batch.markImporting, throwsStateError);
    expect(batch.fail, throwsStateError);
    expect(batch.cancel, throwsStateError);
    expect(batch.complete, throwsStateError);
  });

  test('row cannot move from error to imported', () {
    final row = CustomerPriceRuleImportRow(id: 'r1', rowNumber: 2)..markError();
    expect(row.markImported, throwsStateError);
  });

  test('row requires validation before terminal processing', () {
    final parsed = CustomerPriceRuleImportRow(id: 'r1', rowNumber: 2);

    expect(parsed.markImported, throwsStateError);
    expect(parsed.markSkipped, throwsStateError);
    expect(parsed.markFailed, throwsStateError);
  });

  test('row terminal statuses are immutable', () {
    final imported = CustomerPriceRuleImportRow(id: 'r1', rowNumber: 2)
      ..markValid()
      ..markImported();
    final skipped = CustomerPriceRuleImportRow(id: 'r2', rowNumber: 3)
      ..markError()
      ..markSkipped();

    expect(imported.markFailed, throwsStateError);
    expect(imported.markError, throwsStateError);
    expect(skipped.markImported, throwsStateError);
    expect(skipped.markValid, throwsStateError);
  });

  test('version must stay positive', () {
    expect(
      () => CustomerPriceRuleImport(
        id: 'import-1',
        mode: CustomerPriceRuleImportMode.upsert,
        version: 0,
      ),
      throwsArgumentError,
    );
  });
}
