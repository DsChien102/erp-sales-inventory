import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets(
    'preview permits partial import when valid or warning rows remain',
    (tester) async {
      final cubit = _cubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        _host(
          PriceRuleImportPreviewView(
            cubit: cubit,
            importDetail: _detail(validRows: 1, warningRows: 1, errorRows: 1),
            rows: const [],
          ),
        ),
      );

      expect(_button(tester, 'Tiếp tục').onPressed, isNotNull);
      expect(
        find.text('Hệ thống đã kiểm tra file. Vui lòng xem kết quả.'),
        findsOneWidget,
      );
      expect(find.text('Tổng dòng'), findsOneWidget);
      expect(find.textContaining('Dữ liệu hợp lệ'), findsOneWidget);
    },
  );

  testWidgets('preview disables continue when no row is importable', (
    tester,
  ) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        PriceRuleImportPreviewView(
          cubit: cubit,
          importDetail: _detail(validRows: 0, warningRows: 0, errorRows: 2),
          rows: const [],
        ),
      ),
    );

    expect(_button(tester, 'Tiếp tục').onPressed, isNull);
  });

  testWidgets('read-only preview hides continue and shows back to result', (
    tester,
  ) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        PriceRuleImportPreviewView(
          cubit: cubit,
          importDetail: _detail(validRows: 1, warningRows: 0, errorRows: 0),
          rows: const [],
          readOnly: true,
        ),
      ),
    );

    expect(find.text('Tiếp tục'), findsNothing);
    expect(find.text('Quay lại kết quả'), findsOneWidget);
  });

  testWidgets('choose file disables continue until a file is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const PriceRuleImportChooseFileView()),
    );
    expect(_button(tester, 'Tiếp tục').onPressed, isNull);

    await tester.pumpWidget(
      _host(
        PriceRuleImportChooseFileView(
          selectedFileName: 'demo.xlsx',
          selectedFileSizeBytes: 2048,
          onContinue: () {},
        ),
      ),
    );
    expect(find.text('demo.xlsx'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
    expect(_button(tester, 'Tiếp tục').onPressed, isNotNull);
  });

  testWidgets('confirm counts warning rows and requires acknowledgement', (
    tester,
  ) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        PriceRuleImportConfirmView(
          cubit: cubit,
          importDetail: _detail(validRows: 1, warningRows: 1, errorRows: 1),
          acknowledgeWarningRows: false,
        ),
      ),
    );

    expect(find.text('Nhập (2 dòng)'), findsOneWidget);
    expect(_button(tester, 'Nhập (2 dòng)').onPressed, isNull);
    expect(find.text('Cập nhật giá nhớ hiện tại'), findsOneWidget);
    expect(find.text('Bỏ qua, giữ nguyên giá hiện tại'), findsOneWidget);
    expect(find.text('Chỉ cập nhật rule đã có'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        PriceRuleImportConfirmView(
          cubit: cubit,
          importDetail: _detail(validRows: 1, warningRows: 1, errorRows: 1),
          acknowledgeWarningRows: true,
        ),
      ),
    );
    expect(_button(tester, 'Nhập (2 dòng)').onPressed, isNotNull);
  });

  testWidgets('result shows partial outcome and review links', (tester) async {
    await tester.pumpWidget(
      _host(
        PriceRuleImportResultView(
          result: _result(
            importedRows: 2,
            skippedRows: 1,
            failedRows: 1,
            validRows: 2,
            warningRows: 1,
            errorRows: 1,
          ),
          outcome: PriceRuleImportOutcome.partial,
        ),
      ),
    );

    expect(find.text('Nhập một phần'), findsOneWidget);
    expect(find.textContaining('Dữ liệu hợp lệ'), findsOneWidget);
    expect(find.textContaining('Cảnh báo'), findsWidgets);
    expect(find.textContaining('Lỗi'), findsWidgets);
  });

  testWidgets('wizard shows no-permission empty state', (tester) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        PriceRuleImportWizard(
          cubit: cubit,
          state: const PriceRuleImportNoPermission(),
        ),
      ),
    );

    expect(find.text('Không có quyền nhập'), findsOneWidget);
  });

  testWidgets('wizard explains file-level errors in Vietnamese', (
    tester,
  ) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        PriceRuleImportWizard(
          cubit: cubit,
          state: const PriceRuleImportError(
            code: 'TEMPLATE_HEADER_INVALID',
            step: PriceRuleImportStep.chooseFile,
          ),
        ),
      ),
    );

    expect(find.textContaining('cột tiêu đề'), findsOneWidget);
  });

  testWidgets('preview row renders duplicate as an error in Vietnamese', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PriceRuleImportRowTile(
          row: _row(
            errorCodes: const ['DUPLICATE_ACTIVE_RULE'],
            warningCodes: const [
              'EFFECTIVE_FROM_DEFAULTED',
              'BELOW_FLOOR_PRICE',
            ],
          ),
        ),
      ),
    );

    expect(
      find.text('Đã tồn tại giá riêng đang hoạt động trùng thời gian.'),
      findsOneWidget,
    );
    expect(
      find.text('Ngày bắt đầu để trống, hệ thống sẽ dùng ngày hiện tại.'),
      findsOneWidget,
    );
    expect(
      find.text('Giá riêng 10.000đ thấp hơn giá sàn 10.500đ.'),
      findsOneWidget,
    );
    expect(find.textContaining('DUPLICATE_ACTIVE_RULE'), findsNothing);
  });

  testWidgets(
    'preview row preserves unknown issue codes in Vietnamese fallback',
    (tester) async {
      await tester.pumpWidget(
        _host(
          PriceRuleImportRowTile(
            row: _row(
              errorCodes: const ['UNKNOWN_ERROR'],
              warningCodes: const ['UNKNOWN_WARNING'],
            ),
          ),
        ),
      );

      expect(find.text('Lỗi chưa xác định (UNKNOWN_ERROR).'), findsOneWidget);
      expect(
        find.text('Cảnh báo chưa xác định (UNKNOWN_WARNING).'),
        findsOneWidget,
      );
    },
  );

  testWidgets('preview shows selected conversion unit identity', (tester) async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    final conversionRow = CustomerPriceRuleImportRowPreviewDto(
      id: 'row-1',
      rowNumber: 2,
      ruleId: null,
      customerId: '00000000-0000-4000-8000-000000000001',
      productId: '00000000-0000-4000-8000-000000000101',
      productUnitId: '00000000-0000-4000-8000-000000000202',
      price: '100000',
      effectiveFrom: null,
      effectiveTo: null,
      note: null,
      productSnapshot: const {'product_name': 'Vaccine'},
      unitSnapshot: const {
        'unit_name': 'Hộp 10 liều',
        'is_base_unit': false,
      },
      unitResolutionStrategy: ProductUnitResolutionStrategy.explicitSelection,
      status: CustomerPriceRuleImportRowStatus.valid,
      action: CustomerPriceRuleImportAction.create,
      errorCodes: const [],
      warningCodes: const [],
    );

    await tester.pumpWidget(
      _host(
        PriceRuleImportPreviewView(
          cubit: cubit,
          importDetail: _detail(validRows: 1, warningRows: 0, errorRows: 0),
          rows: [conversionRow],
        ),
      ),
    );

    expect(find.text('Vaccine'), findsOneWidget);
    expect(find.textContaining('Hộp 10 liều'), findsOneWidget);
    expect(find.textContaining('Đơn vị quy đổi'), findsOneWidget);
  });

  testWidgets(
    'REFERENCE_INVALID message mentions customer, product, or unit',
    (tester) async {
      await tester.pumpWidget(
        _host(
          PriceRuleImportRowTile(
            row: _row(
              errorCodes: const ['REFERENCE_INVALID'],
              warningCodes: const [],
            ),
          ),
        ),
      );

      expect(
        find.text('Không tìm thấy khách hàng, sản phẩm hoặc đơn vị hợp lệ.'),
        findsOneWidget,
      );
    },
  );

}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

VButton _button(WidgetTester tester, String label) => tester.widget<VButton>(
  find.byWidgetPredicate(
    (widget) => widget is VButton && widget.label == label,
  ),
);

PriceRuleImportCubit _cubit() => PriceRuleImportCubit(
  pricingModule: _NoopPricingModule(),
  executionContext: FakeExecutionContext(
    tenantId: 'tenant-1',
    userId: 'user-1',
  ),
);

CustomerPriceRuleImportDetailDto _detail({
  required int validRows,
  required int warningRows,
  required int errorRows,
}) => CustomerPriceRuleImportDetailDto(
  batch: CustomerPriceRuleImportDto(
    id: 'import-1',
    templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
    originalFileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
    importMode: CustomerPriceRuleImportMode.upsert,
    status: CustomerPriceRuleImportStatus.readyToImport,
    version: 1,
    totalRows: validRows + warningRows + errorRows,
    validRows: validRows,
    warningRows: warningRows,
    errorRows: errorRows,
    importedRows: 0,
    skippedRows: 0,
    failedRows: 0,
    fileErrorCodes: const [],
    createdAt: DateTime.utc(2026, 7, 21),
  ),
  rows: const CursorPageDto(items: [], hasMore: false),
);

CustomerPriceRuleImportResultDto _result({
  required int importedRows,
  required int skippedRows,
  required int failedRows,
  required int validRows,
  required int warningRows,
  required int errorRows,
}) => CustomerPriceRuleImportResultDto(
  batch: CustomerPriceRuleImportDto(
    id: 'import-1',
    templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
    originalFileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
    importMode: CustomerPriceRuleImportMode.upsert,
    status: CustomerPriceRuleImportStatus.completedWithErrors,
    version: 2,
    totalRows: validRows + warningRows + errorRows,
    validRows: validRows,
    warningRows: warningRows,
    errorRows: errorRows,
    importedRows: importedRows,
    skippedRows: skippedRows,
    failedRows: failedRows,
    fileErrorCodes: const [],
    createdAt: DateTime.utc(2026, 7, 21),
  ),
  processedAt: DateTime.utc(2026, 7, 21, 12),
  isReplay: false,
);

CustomerPriceRuleImportRowPreviewDto _row({
  required List<String> errorCodes,
  required List<String> warningCodes,
}) => CustomerPriceRuleImportRowPreviewDto(
  id: 'row-1',
  rowNumber: 2,
  ruleId: null,
  customerId: '43be4cdf-f9f8-4721-a105-d6a2376205c7',
  productId: '00000000-0000-4000-8000-000000000101',
  productUnitId: '00000000-0000-4000-8000-000000000201',
  price: '10000',
  effectiveFrom: null,
  effectiveTo: null,
  note: 'Import thử',
  customerSnapshot: const {'display_name': 'Ds Chien'},
  productSnapshot: const {'product_name': 'abc', 'floor_price_minor': 10500},
  unitSnapshot: const {'unit_name': 'b', 'is_base_unit': true},
  unitResolutionStrategy: ProductUnitResolutionStrategy.explicitSelection,
  normalizedPriceMinor: 10000,
  status: errorCodes.isNotEmpty
      ? CustomerPriceRuleImportRowStatus.error
      : CustomerPriceRuleImportRowStatus.warning,
  action: errorCodes.isNotEmpty
      ? CustomerPriceRuleImportAction.skip
      : CustomerPriceRuleImportAction.create,
  errorCodes: errorCodes,
  warningCodes: warningCodes,
);

final class _NoopPricingModule implements IPricingModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) =>
      throw UnsupportedError('No command expected');

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) =>
      throw UnsupportedError('No query expected');
}
