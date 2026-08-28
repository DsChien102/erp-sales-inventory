import 'package:equatable/equatable.dart';

import '../../shared/services/configuration_readiness_evaluator.dart'
    show ReadinessBlocker, ReadinessWarning;
import '../enums/buyer_completion_status.dart';
import '../enums/issuance_readiness_level.dart';
import 'issuance_readiness_input.dart';

/// Result of per-order issuance readiness evaluation (read model).
final class IssuanceReadinessEvaluation extends Equatable {
  const IssuanceReadinessEvaluation({
    required this.level,
    required this.blockers,
    required this.warnings,
    required this.canPreview,
    required this.buyerCompletionState,
  });

  final IssuanceReadinessLevel level;
  final List<ReadinessBlocker> blockers;
  final List<ReadinessWarning> warnings;
  final bool canPreview;
  final BuyerCompletionStatus buyerCompletionState;

  @override
  List<Object?> get props => [
        level,
        blockers,
        warnings,
        canPreview,
        buyerCompletionState,
      ];
}

/// Pure evaluator for EP-02/US-01 issuance readiness.
abstract final class IssuanceReadinessEvaluator {
  static IssuanceReadinessEvaluation evaluate(IssuanceReadinessInput input) {
    final blockers = <ReadinessBlocker>[];
    var previewForbidden = false;

    if (!input.orderCompleted) {
      blockers.add(
        const ReadinessBlocker(
          code: 'ORDER_NOT_COMPLETED',
          message: 'Đơn hàng chưa Hoàn tất',
        ),
      );
      previewForbidden = true;
    }

    if (input.hasElectronicInvoice) {
      blockers.add(
        const ReadinessBlocker(
          code: 'ALREADY_ISSUED',
          message: 'Đơn hàng đã có hóa đơn điện tử',
        ),
      );
      previewForbidden = true;
    }

    if (input.hasActiveOperation) {
      blockers.add(
        const ReadinessBlocker(
          code: 'OPERATION_IN_PROGRESS',
          message: 'Đang có thao tác phát hành khác',
        ),
      );
      previewForbidden = true;
    }

    if (!input.configReady) {
      blockers.add(
        const ReadinessBlocker(
          code: 'CONFIG_NOT_READY',
          message: 'Cấu hình phát hành chưa sẵn sàng',
        ),
      );
      previewForbidden = true;
    }

    if (!input.providerConnected) {
      blockers.add(
        const ReadinessBlocker(
          code: 'PROVIDER_NOT_CONNECTED',
          message: 'Chưa kết nối nhà cung cấp',
        ),
      );
      previewForbidden = true;
    }

    // FR-06 / EC-04: commercial data must map to CanonicalInvoiceModel; if not,
    // block readiness and forbid preview (do not send a preview request).
    if (!input.commercialDataMappable) {
      blockers.add(
        const ReadinessBlocker(
          code: 'VALIDATION_ERROR',
          message: 'Dữ liệu thương mại không ánh xạ được sang hóa đơn',
        ),
      );
      previewForbidden = true;
    }

    if (input.buyer.isMissingOnlyOrgTaxCode) {
      blockers.add(
        const ReadinessBlocker(
          code: 'BUYER_TAX_CODE_REQUIRED',
          message: 'Khách tổ chức thiếu mã số thuế',
        ),
      );
    } else if (!input.buyer.isComplete) {
      blockers.add(
        const ReadinessBlocker(
          code: 'BUYER_DATA_INCOMPLETE',
          message: 'Thông tin người mua chưa đủ',
        ),
      );
      previewForbidden = true;
    }

    final canPreview = !previewForbidden && input.providerSupportsPreview;
    final warnings = List<ReadinessWarning>.unmodifiable(input.configWarnings);

    final IssuanceReadinessLevel level;
    if (blockers.isNotEmpty) {
      level = IssuanceReadinessLevel.notReady;
    } else if (warnings.isNotEmpty) {
      level = IssuanceReadinessLevel.readyWithWarnings;
    } else {
      level = IssuanceReadinessLevel.ready;
    }

    return IssuanceReadinessEvaluation(
      level: level,
      blockers: List<ReadinessBlocker>.unmodifiable(blockers),
      warnings: warnings,
      canPreview: canPreview,
      buyerCompletionState: input.buyerCompletionState,
    );
  }
}
