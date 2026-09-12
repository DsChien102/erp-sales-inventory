import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_cubit_test_stubs.dart';
import '../support/compose_line_test_data.dart';

void main() {
  group('SalesComposeCubit draft backend', () {
    test('first save persists create request and adopts server draft id/version', () async {
      final persistCalls = <SalesDraftPersistRequest>[];
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          persistCalls.add(request);
          return _draftDto(
            draftId: 'server-draft-1',
            version: 1,
            lines: request.lines,
            customer: request.customer,
            orderNote: request.orderNote,
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.setCustomer(_customer);
      cubit.setOrderNote('Giao sáng');
      cubit.addOrIncrementLine(_selection);
      await _flush();

      final ok = await cubit.saveDraft();

      expect(ok, isTrue);
      expect(persistCalls, hasLength(1));
      expect(persistCalls.single.draftId, isNull);
      expect(persistCalls.single.expectedVersion, isNull);
      expect(persistCalls.single.isUpdate, isFalse);
      expect(persistCalls.single.composeSessionId, isNotEmpty);
      expect(persistCalls.single.customer.partnerId, 'customer-1');
      expect(persistCalls.single.orderNote, 'Giao sáng');
      expect(persistCalls.single.lines, hasLength(1));
      expect(cubit.state.draftId, 'server-draft-1');
      expect(cubit.state.draftVersion, 1);
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saved);
      expect(cubit.state.saveMessage, isNull);
    });

    test('successful save adopts server line ids from persist response', () async {
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          return _draftDto(
            draftId: 'server-draft-1',
            version: 1,
            lines: request.lines,
            customer: request.customer,
            orderNote: request.orderNote,
            serverLineIds: const ['server-line-uuid-1'],
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();

      final localLineId = cubit.state.lines.single.identity.lineId;
      expect(localLineId, startsWith('line-'));

      final ok = await cubit.saveDraft();

      expect(ok, isTrue);
      expect(cubit.state.lines.single.identity.lineId, 'server-line-uuid-1');
      expect(cubit.state.lines.single.identity.lineId, isNot(localLineId));
      expect(cubit.state.lines.single.pricing.lineTotal?.amountMinor, 100000);
    });

    test('second save updates with expected version from prior persist', () async {
      final persistCalls = <SalesDraftPersistRequest>[];
      var version = 0;
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          persistCalls.add(request);
          version += 1;
          return _draftDto(
            draftId: request.draftId ?? 'server-draft-1',
            version: version,
            lines: request.lines,
            customer: request.customer,
            orderNote: request.orderNote,
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      await cubit.saveDraft();

      cubit.setOrderNote('Ghi chú cập nhật');
      final ok = await cubit.saveDraft();

      expect(ok, isTrue);
      expect(persistCalls, hasLength(2));
      expect(persistCalls[1].isUpdate, isTrue);
      expect(persistCalls[1].draftId, 'server-draft-1');
      expect(persistCalls[1].expectedVersion, 1);
      expect(cubit.state.draftVersion, 2);
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saved);
    });

    test('save failure preserves lines/customer/note and sets error for retry', () async {
      var failOnce = true;
      final persistCalls = <SalesDraftPersistRequest>[];
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          persistCalls.add(request);
          if (failOnce) {
            failOnce = false;
            throw const SalesExternalOperationException(
              'Không lưu được đơn nháp. Kiểm tra sản phẩm hoặc khách hàng.',
            );
          }
          return _draftDto(
            draftId: 'server-draft-1',
            version: 1,
            lines: request.lines,
            customer: request.customer,
            orderNote: request.orderNote,
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.setCustomer(_customer);
      cubit.setOrderNote('Giữ lại khi lỗi');
      cubit.addOrIncrementLine(_selection);
      await _flush();
      final linesBefore = cubit.state.lines;
      final sessionBefore = persistCalls.isEmpty ? null : persistCalls.first.composeSessionId;

      final failed = await cubit.saveDraft();
      expect(failed, isFalse);
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.error);
      expect(cubit.state.saveMessage, contains('Không lưu được'));
      expect(cubit.state.customer.partnerId, 'customer-1');
      expect(cubit.state.orderNote, 'Giữ lại khi lỗi');
      expect(cubit.state.lines, linesBefore);
      expect(cubit.state.draftId, 'draft-new');
      expect(cubit.state.hasUnsavedChanges, isTrue);

      final firstSession = persistCalls.single.composeSessionId;
      expect(sessionBefore ?? firstSession, firstSession);

      final retried = await cubit.saveDraft();
      expect(retried, isTrue);
      expect(persistCalls, hasLength(2));
      expect(persistCalls[1].composeSessionId, firstSession);
      expect(persistCalls[1].draftId, isNull);
      expect(cubit.state.draftId, 'server-draft-1');
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saved);
      expect(cubit.state.saveMessage, isNull);
    });

    test('restore hydrates snapshot and keeps restore issues visible', () async {
      final cubit = _cubit(
        draftId: 'server-draft-9',
        restore: (draftId) async {
          expect(draftId, 'server-draft-9');
          return SalesDraftRestoreResult(
            draft: _draftDto(
              draftId: draftId,
              version: 4,
              lines: [_lineVm],
              customer: _customer,
              orderNote: 'Từ máy chủ',
            ),
            customer: _customer,
            lines: [_lineVm],
            orderNote: 'Từ máy chủ',
            issues: const [
              SalesDraftRestoreIssue(
                code: SalesDraftRestoreIssueCode.pricingChanged,
                lineId: 'line-1',
                message: 'Giá đã thay đổi',
              ),
            ],
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      await _flush();

      expect(cubit.state, isA<SalesComposeLoaded>());
      expect(cubit.state.draftId, 'server-draft-9');
      expect(cubit.state.draftVersion, 4);
      expect(cubit.state.customer.partnerId, 'customer-1');
      expect(cubit.state.orderNote, 'Từ máy chủ');
      expect(cubit.state.lines.single.identity.productId, 'product-1');
      expect(cubit.state.restoreIssues, hasLength(1));
      expect(
        cubit.state.restoreIssues.single.code,
        SalesDraftRestoreIssueCode.pricingChanged,
      );
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saved);
    });

    test('failed restore emits error without checkout-capable empty draft', () async {
      final cubit = _cubit(
        draftId: 'missing-draft',
        restore: (_) async {
          throw const SalesExternalOperationException(
            'Không tìm thấy đơn nháp.',
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();

      expect(cubit.state, isA<SalesComposeError>());
      final error = cubit.state as SalesComposeError;
      expect(error.message, contains('Không'));
      expect(error.lines, isEmpty);
      expect(error.canCheckout, isFalse);
      expect(error.canSaveDraft, isFalse);
      expect(error, isNot(isA<SalesComposeLoaded>()));
    });

    test('mutators no-op on restore error — do not emit empty Loaded', () async {
      final cubit = _cubit(
        draftId: 'missing-draft',
        restore: (_) async {
          throw const SalesExternalOperationException(
            'Không tìm thấy đơn nháp.',
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      expect(cubit.state, isA<SalesComposeError>());

      cubit.setOrderNote('không được áp');
      expect(cubit.state, isA<SalesComposeError>());
      expect(cubit.state.orderNote, isNull);

      cubit.setCustomer(_customer);
      expect(cubit.state, isA<SalesComposeError>());
      expect(cubit.state.customer.isWalkIn, isTrue);

      cubit.addOrIncrementLine(_selection);
      await _flush();
      expect(cubit.state, isA<SalesComposeError>());
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.canCheckout, isFalse);
      expect(cubit.state.canSaveDraft, isFalse);
      expect(cubit.state, isNot(isA<SalesComposeLoaded>()));
    });

    test('saveDraft returns false while already saving', () async {
      final persistStarted = Completer<void>();
      final allowPersist = Completer<SalesOrderDraftDto>();
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (_) async {
          persistStarted.complete();
          return allowPersist.future;
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();

      final first = cubit.saveDraft();
      await persistStarted.future;
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saving);

      final second = await cubit.saveDraft();
      expect(second, isFalse);

      allowPersist.complete(
        _draftDto(
          draftId: 'server-draft-1',
          version: 1,
          lines: cubit.state.lines,
          customer: cubit.state.customer,
        ),
      );
      expect(await first, isTrue);
      expect(cubit.state.saveStatus, SalesComposeSaveStatus.saved);
    });

    test('new draft hydrate does not call restore and stays empty ready', () async {
      var restoreCalls = 0;
      final cubit = _cubit(
        draftId: 'draft-new',
        restore: (_) async {
          restoreCalls += 1;
          throw StateError('must not restore new draft');
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();

      expect(restoreCalls, 0);
      expect(cubit.state, isA<SalesComposeLoaded>());
      expect(cubit.state.draftId, 'draft-new');
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.pricingStatus, SalesComposePricingStatus.ready);
      expect(cubit.state.draftVersion, isNull);
    });
  });
}

SalesComposeCubit _cubit({
  required String draftId,
  SalesDraftPersistFn? persist,
  SalesDraftRestoreFn? restore,
}) {
  return composeTestCubit(
    draftId: draftId,
    previewPricing: (request) async => _pricingSuccess(request),
    persistDraft: persist ?? (_) async => throw StateError('persist must not be called'),
    restoreDraft: restore ?? (_) async => throw StateError('restore must not be called'),
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

SalesPricingPreviewResult _pricingSuccess(SalesPricingPreviewRequest request) {
  return SalesPricingPreviewResult(
    contextVersion: request.contextVersion,
    previewToken: 'token-${request.contextVersion}',
    currencyCode: request.currencyCode,
    lines: request.lines
        .map(
          (line) => SalesPricingLineResult(
            localLineId: line.localLineId,
            appliedUnitPrice: const MoneyDto(
              amountMinor: 100000,
              currencyCode: 'VND',
            ),
            discount: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            lineTotal: MoneyDto(
              amountMinor: 100000 * line.quantityMicros ~/ 1000000,
              currencyCode: 'VND',
            ),
            sourceCode: 'LIST_PRICE',
            listUnitPrice: const MoneyDto(
              amountMinor: 100000,
              currencyCode: 'VND',
            ),
            floorUnitPrice: const MoneyDto(
              amountMinor: 80000,
              currencyCode: 'VND',
            ),
            warningCodes: const [],
            blockingCodes: const [],
          ),
        )
        .toList(growable: false),
  );
}

SalesOrderDraftDto _draftDto({
  required String draftId,
  required int version,
  required List<SalesComposeLineVm> lines,
  required SalesComposeCustomerVm customer,
  String? orderNote,
  List<String>? serverLineIds,
}) {
  return SalesOrderDraftDto(
    draftId: draftId,
    version: version,
    status: SalesDraftStatus.active,
    storeId: 'store-1',
    savedAt: DateTime.utc(2026, 8, 11, 5),
    savedByActorId: 'actor-1',
    customer: customer.isWalkIn
        ? null
        : CustomerSnapshotDto(
            customerId: customer.partnerId!,
            displayName: customer.displayName,
            phoneNumber: customer.phone,
          ),
    orderNote: orderNote,
    lines: [
      for (var i = 0; i < lines.length; i++)
        SalesOrderDraftLineDto(
          lineId: serverLineIds != null ? serverLineIds[i] : lines[i].identity.lineId,
          productId: lines[i].identity.productId,
          productSku: 'SP-1',
          productName: lines[i].identity.productName,
          productUnitId: lines[i].identity.productUnitId,
          unitCode: 'BOX',
          unitName: lines[i].identity.unitLabel,
          quantity: QuantityDto(quantityMicros: lines[i].input.quantity * 1000000),
          appliedUnitPrice: lines[i].pricing.appliedUnitPrice,
          lineTotal: MoneyDto(
            amountMinor: lines[i].lineTotalMinor,
            currencyCode: lines[i].pricing.appliedUnitPrice.currencyCode,
          ),
          listUnitPrice: lines[i].pricing.listUnitPrice,
        ),
    ],
    total: MoneyDto(
      amountMinor: lines.fold<int>(0, (sum, line) => sum + line.lineTotalMinor),
      currencyCode: 'VND',
    ),
  );
}

const _customer = SalesComposeCustomerVm(
  displayName: 'Khách A',
  partnerId: 'customer-1',
  phone: '0900000001',
);

const _selection = SalesProductSelection(
  productId: 'product-1',
  productUnitId: 'unit-1',
  productName: 'Thuốc A',
  sku: 'SP-1',
  unitLabel: 'Hộp',
  unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
);

final _lineVm = composeTestLine(
  lineId: 'line-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  productName: 'Thuốc A',
  unitLabel: 'Hộp',
  quantity: 2,
  baseUnitPrice: composeTestMoney(100000),
  appliedUnitPrice: composeTestMoney(100000),
  listUnitPrice: composeTestMoney(100000),
);
