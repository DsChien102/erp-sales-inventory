import 'package:erp/features/sales/presentation/models/sales_order/sales_order_actions_vm.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_post_sale_navigation_intent.dart';
import 'package:erp/features/sales/presentation/support/sales_order_cancellation_attempt_factory.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'sales_order_detail_sections_loader.dart';
import 'sales_order_detail_state.dart';

/// Runs S21 authoritative prechecks and returns navigation intents (no BuildContext).
final class SalesOrderDetailPostSaleActions {
  SalesOrderDetailPostSaleActions({
    required this.orderId,
    required this.salesModule,
    required this.executionContext,
    required this.isClosed,
    required this.currentGeneration,
    required this.readState,
    required this.emitTransform,
    required this.reloadCore,
    required this.sectionsLoader,
    SalesOrderCancellationAttemptFactory? cancellationAttemptFactory,
  }) : _cancellationAttemptFactory =
           cancellationAttemptFactory ?? SalesOrderCancellationAttemptFactory();

  final String orderId;
  final ISalesModule salesModule;
  final IExecutionContext executionContext;
  final bool Function() isClosed;
  final int Function() currentGeneration;
  final SalesOrderDetailState Function() readState;
  final SalesOrderDetailStateEmitter emitTransform;
  final Future<void> Function() reloadCore;
  final SalesOrderDetailSectionsLoader Function() sectionsLoader;
  final SalesOrderCancellationAttemptFactory _cancellationAttemptFactory;

  Future<void> retryActionsSection() async {
    final state = readState();
    final sourceVersion = state.sourceVersion;
    if (state.status != SalesOrderDetailStatus.loaded || sourceVersion == null) return;
    final generation = state.requestGeneration;
    if (isClosed() || generation != currentGeneration()) return;
    await sectionsLoader().loadActions(
      generation: generation,
      sourceVersion: sourceVersion,
    );
  }

  Future<SalesPostSaleNavigationIntent?> requestCancel() {
    return _runPrecheck(
      intent: SalesPostSaleNavigationIntent.cancel,
      execute: (tenantId, actorId, sourceVersion) {
        return salesModule.executeQueryAsync<CancellationPrecheckDto>(
          PrecheckSalesOrderCancellationQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: orderId,
            expectedSourceVersion: sourceVersion,
          ),
        );
      },
      allowedOf: (dto) => dto.allowed,
      blockersOf: (dto) => dto.blockers,
      disableOnPermissionDenied: (actions) => actions.copyWith(canCancel: false),
    );
  }

  Future<SalesPostSaleNavigationIntent?> requestReturnExchange() {
    return _runPrecheck(
      intent: SalesPostSaleNavigationIntent.returnExchange,
      execute: (tenantId, actorId, sourceVersion) {
        return salesModule.executeQueryAsync<ReturnExchangePrecheckDto>(
          PrecheckReturnExchangeQuery(
            tenantId: tenantId,
            actorId: actorId,
            salesOrderId: orderId,
            expectedSourceVersion: sourceVersion,
          ),
        );
      },
      allowedOf: (dto) => dto.allowed,
      blockersOf: (dto) => dto.blockers,
      disableOnPermissionDenied: (actions) => actions.copyWith(canReturnExchange: false),
    );
  }

  /// Confirms SG-10 cancellation from the detail sheet.
  /// Returns `null` on success; otherwise a user-facing error message.
  Future<String?> confirmCancellation({required String note}) async {
    final snapshot = readState();
    if (snapshot.status != SalesOrderDetailStatus.loaded || snapshot.sourceVersion == null) {
      return 'Chưa tải xong dữ liệu đơn hàng.';
    }
    final generation = snapshot.requestGeneration;
    final trimmedNote = note.trim();

    try {
      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      if (isClosed() || generation != currentGeneration()) {
        return 'Huỷ đơn thất bại. Vui lòng thử lại.';
      }

      final precheck = await salesModule.executeQueryAsync<CancellationPrecheckDto>(
        PrecheckSalesOrderCancellationQuery(
          tenantId: tenantId,
          actorId: actorId,
          salesOrderId: orderId,
          expectedSourceVersion: snapshot.sourceVersion,
        ),
      );
      if (isClosed() || generation != currentGeneration()) {
        return 'Huỷ đơn thất bại. Vui lòng thử lại.';
      }

      if (!precheck.allowed) {
        final messages = precheck.blockers
            .map((blocker) => blocker.message)
            .where((message) => message.trim().isNotEmpty)
            .toList(growable: false);
        return messages.isEmpty ? 'Không thể huỷ đơn.' : messages.join('\n');
      }

      final attempt = _cancellationAttemptFactory.create(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: orderId,
        expectedOrderVersion: precheck.sourceVersion,
        expectedSettlementVersion: precheck.sourceSettlementVersion,
        reasonText: trimmedNote,
        correlationId: executionContext.correlationId,
      );
      final result = await salesModule.executeCommandAsync<SalesOrderCancellationResultDto>(
        attempt.command,
      );
      if (isClosed() || generation != currentGeneration()) {
        return 'Huỷ đơn thất bại. Vui lòng thử lại.';
      }

      switch (result.status) {
        case SalesOrderCancellationStatus.confirmed:
        case SalesOrderCancellationStatus.completed:
        case SalesOrderCancellationStatus.processing:
          return null;
        case SalesOrderCancellationStatus.requested:
        case SalesOrderCancellationStatus.validating:
        case SalesOrderCancellationStatus.blocked:
        case SalesOrderCancellationStatus.failed:
        case SalesOrderCancellationStatus.cancelled:
          return 'Huỷ đơn chưa hoàn tất.';
      }
    } on SalesContractException catch (error) {
      if (isClosed() || generation != currentGeneration()) {
        return 'Huỷ đơn thất bại. Vui lòng thử lại.';
      }
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) return message;
      return 'Huỷ đơn thất bại. Vui lòng thử lại.';
    } on Object {
      if (isClosed() || generation != currentGeneration()) {
        return 'Huỷ đơn thất bại. Vui lòng thử lại.';
      }
      return 'Huỷ đơn thất bại. Vui lòng thử lại.';
    }
  }

  Future<SalesPostSaleNavigationIntent?> _runPrecheck<T>({
    required SalesPostSaleNavigationIntent intent,
    required Future<T> Function(String tenantId, String actorId, int sourceVersion) execute,
    required bool Function(T dto) allowedOf,
    required List<SalesBlockerDto> Function(T dto) blockersOf,
    required SalesOrderActionsVm Function(SalesOrderActionsVm actions) disableOnPermissionDenied,
  }) async {
    final snapshot = readState();
    final sourceVersion = snapshot.sourceVersion;
    if (snapshot.status != SalesOrderDetailStatus.loaded || sourceVersion == null) {
      return null;
    }
    final generation = snapshot.requestGeneration;
    emitTransform(
      (state) => state.copyWith(
        clearPrecheckBlockerMessages: true,
        clearPostSaleFeedbackMessage: true,
      ),
    );

    try {
      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      if (isClosed() || generation != currentGeneration()) return null;

      final dto = await execute(tenantId, actorId, sourceVersion);
      if (isClosed() || generation != currentGeneration()) return null;

      if (!allowedOf(dto)) {
        final messages = blockersOf(dto)
            .map((blocker) => blocker.message)
            .where((message) => message.isNotEmpty)
            .toList(growable: false);
        final feedback = messages.isEmpty
            ? 'Không thể thực hiện thao tác này trên đơn hàng.'
            : messages.join('\n');
        emitTransform(
          (state) => state.copyWith(
            precheckBlockerMessages: messages,
            postSaleFeedbackMessage: feedback,
          ),
        );
        return null;
      }

      emitTransform(
        (state) => state.copyWith(
          clearPrecheckBlockerMessages: true,
          clearPostSaleFeedbackMessage: true,
        ),
      );
      return intent;
    } catch (error) {
      if (isClosed() || generation != currentGeneration()) return null;
      return _handlePrecheckFailure(
        error,
        disableOnPermissionDenied: disableOnPermissionDenied,
      );
    }
  }

  Future<SalesPostSaleNavigationIntent?> _handlePrecheckFailure(
    Object error, {
    required SalesOrderActionsVm Function(SalesOrderActionsVm actions) disableOnPermissionDenied,
  }) async {
    final contract = error is SalesContractException ? error : null;
    if (contract?.code == 'STALE_VERSION') {
      emitTransform(
        (state) => state.copyWith(
          actionsStatus: SalesOrderDetailSectionStatus.idle,
          clearActions: true,
          clearActionsErrorMessage: true,
          clearPrecheckBlockerMessages: true,
          clearPostSaleFeedbackMessage: true,
        ),
      );
      await reloadCore();
      if (isClosed()) return null;
      emitTransform(
        (state) => state.copyWith(
          postSaleFeedbackMessage: 'Đơn hàng đã thay đổi. Hãy tải lại chi tiết rồi thử lại.',
        ),
      );
      return null;
    }

    if (contract?.code == 'PERMISSION_DENIED' || contract?.code == 'DATA_SCOPE_DENIED') {
      final current = readState().actions;
      emitTransform((state) {
        final actions = current == null ? null : disableOnPermissionDenied(current);
        return state.copyWith(
          actions: actions,
          clearActions: actions == null,
          postSaleFeedbackMessage: 'Bạn không có quyền thực hiện thao tác này trên đơn hàng.',
          clearPrecheckBlockerMessages: true,
        );
      });
      return null;
    }

    final message = contract?.message;
    emitTransform(
      (state) => state.copyWith(
        postSaleFeedbackMessage: (message != null && message.isNotEmpty)
            ? message
            : 'Không thể kiểm tra điều kiện thao tác. Vui lòng thử lại.',
        clearPrecheckBlockerMessages: true,
      ),
    );
    return null;
  }
}
