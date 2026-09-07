import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('IssuanceReadinessEvaluator', () {
    const validRetailBuyer = EffectiveBuyerInvoiceData(
      buyerType: BuyerType.retail,
      name: 'Khách lẻ',
    );

    const validOrgBuyer = EffectiveBuyerInvoiceData(
      buyerType: BuyerType.organization,
      name: 'Công ty ABC',
      taxCode: '0101234567',
    );

    const readyInput = IssuanceReadinessInput(
      orderCompleted: true,
      hasElectronicInvoice: false,
      hasActiveOperation: false,
      configReady: true,
      providerConnected: true,
      providerSupportsPreview: true,
      buyer: validRetailBuyer,
      buyerCompletionState: BuyerCompletionStatus.locked,
      configWarnings: [],
    );

    test('returns ready and canPreview when all conditions are met', () {
      final result = IssuanceReadinessEvaluator.evaluate(readyInput);

      expect(result.level, equals(IssuanceReadinessLevel.ready));
      expect(result.blockers, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.canPreview, isTrue);
      expect(
        result.buyerCompletionState,
        equals(BuyerCompletionStatus.locked),
      );
    });

    test('FR-06/EC-04: commercial data not mappable blocks readiness and preview', () {
      const input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
        commercialDataMappable: false,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(
        result.blockers.map((b) => b.code),
        contains('VALIDATION_ERROR'),
      );
      expect(result.canPreview, isFalse);
    });

    test('returns readyWithWarnings when warnings exist but no blockers', () {
      const warning = ReadinessWarning(
        code: 'template_deprecated',
        message: 'Mẫu hóa đơn sắp hết hạn',
      );
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validOrgBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
        configWarnings: const [warning],
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(
        result.level,
        equals(IssuanceReadinessLevel.readyWithWarnings),
      );
      expect(result.blockers, isEmpty);
      expect(result.warnings, equals([warning]));
      expect(result.canPreview, isTrue);
    });

    test('blocks when order is not completed and forbids preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: false,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        contains(
          const ReadinessBlocker(
            code: 'ORDER_NOT_COMPLETED',
            message: 'Đơn hàng chưa Hoàn tất',
          ),
        ),
      );
    });

    test('blocks when invoice already issued and forbids preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: true,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        contains(
          const ReadinessBlocker(
            code: 'ALREADY_ISSUED',
            message: 'Đơn hàng đã có hóa đơn điện tử',
          ),
        ),
      );
    });

    test('blocks when operation is in progress and forbids preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: true,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        contains(
          const ReadinessBlocker(
            code: 'OPERATION_IN_PROGRESS',
            message: 'Đang có thao tác phát hành khác',
          ),
        ),
      );
    });

    test('blocks when configuration is not ready and forbids preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: false,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        contains(
          const ReadinessBlocker(
            code: 'CONFIG_NOT_READY',
            message: 'Cấu hình phát hành chưa sẵn sàng',
          ),
        ),
      );
    });

    test('blocks when provider is not connected and forbids preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: false,
        providerSupportsPreview: true,
        buyer: validRetailBuyer,
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        contains(
          const ReadinessBlocker(
            code: 'PROVIDER_NOT_CONNECTED',
            message: 'Chưa kết nối nhà cung cấp',
          ),
        ),
      );
    });

    test(
      'blocks with BUYER_TAX_CODE_REQUIRED and allows preview when org buyer lacks tax code (BR-08 / UI-06)',
      () {
        const orgWithoutTaxCode = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty XYZ',
          taxCode: null,
        );
        final input = IssuanceReadinessInput(
          orderCompleted: true,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
          configReady: true,
          providerConnected: true,
          providerSupportsPreview: true,
          buyer: orgWithoutTaxCode,
          buyerCompletionState: BuyerCompletionStatus.open,
        );

        final result = IssuanceReadinessEvaluator.evaluate(input);

        expect(result.level, equals(IssuanceReadinessLevel.notReady));
        expect(result.canPreview, isTrue);
        expect(
          result.blockers,
          equals([
            const ReadinessBlocker(
              code: 'BUYER_TAX_CODE_REQUIRED',
              message: 'Khách tổ chức thiếu mã số thuế',
            ),
          ]),
        );
        expect(
          result.buyerCompletionState,
          equals(BuyerCompletionStatus.open),
        );
      },
    );

    test('blocks with BUYER_DATA_INCOMPLETE and forbids preview when buyer data is incomplete', () {
      const invalidBuyer = EffectiveBuyerInvoiceData(
        buyerType: BuyerType.retail,
        name: '   ',
      );
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: invalidBuyer,
        buyerCompletionState: BuyerCompletionStatus.open,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        equals([
          const ReadinessBlocker(
            code: 'BUYER_DATA_INCOMPLETE',
            message: 'Thông tin người mua chưa đủ',
          ),
        ]),
      );
      expect(
        result.buyerCompletionState,
        equals(BuyerCompletionStatus.open),
      );
    });

    test(
      'cannot preview when provider does not support preview even if missing only org tax code',
      () {
        const orgWithoutTaxCode = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: 'Công ty XYZ',
          taxCode: '',
        );
        final input = IssuanceReadinessInput(
          orderCompleted: true,
          hasElectronicInvoice: false,
          hasActiveOperation: false,
          configReady: true,
          providerConnected: true,
          providerSupportsPreview: false,
          buyer: orgWithoutTaxCode,
          buyerCompletionState: BuyerCompletionStatus.open,
        );

        final result = IssuanceReadinessEvaluator.evaluate(input);

        expect(result.level, equals(IssuanceReadinessLevel.notReady));
        expect(result.canPreview, isFalse);
        expect(
          result.blockers,
          contains(
            const ReadinessBlocker(
              code: 'BUYER_TAX_CODE_REQUIRED',
              message: 'Khách tổ chức thiếu mã số thuế',
            ),
          ),
        );
        expect(
          result.blockers,
          contains(
            const ReadinessBlocker(
              code: 'PREVIEW_UNSUPPORTED',
              message: 'Nhà cung cấp không hỗ trợ xem trước',
            ),
          ),
        );
      },
    );

    test('adds PREVIEW_UNSUPPORTED when provider does not support preview', () {
      final input = IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: false,
        buyer: const EffectiveBuyerInvoiceData(
          buyerType: BuyerType.retail,
          name: 'Nguyễn Văn A',
        ),
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.canPreview, isFalse);
      expect(
        result.blockers,
        equals([
          const ReadinessBlocker(
            code: 'PREVIEW_UNSUPPORTED',
            message: 'Nhà cung cấp không hỗ trợ xem trước',
          ),
        ]),
      );
    });

    test('accumulates multiple blockers in expected order', () {
      final input = IssuanceReadinessInput(
        orderCompleted: false,
        hasElectronicInvoice: true,
        hasActiveOperation: true,
        configReady: false,
        providerConnected: false,
        providerSupportsPreview: true,
        buyer: const EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization,
          name: '',
          taxCode: '',
        ),
        buyerCompletionState: BuyerCompletionStatus.open,
      );

      final result = IssuanceReadinessEvaluator.evaluate(input);

      expect(result.level, equals(IssuanceReadinessLevel.notReady));
      expect(result.canPreview, isFalse);
      expect(result.blockers.map((b) => b.code), [
        'ORDER_NOT_COMPLETED',
        'ALREADY_ISSUED',
        'OPERATION_IN_PROGRESS',
        'CONFIG_NOT_READY',
        'PROVIDER_NOT_CONNECTED',
        'BUYER_DATA_INCOMPLETE',
      ]);
    });
  });
}
