import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/logic/sales_checkout_error_messages.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_checkout_draft_args.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_checkout_vm.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_checkout_attempt_envelope.dart';
import 'package:erp/features/sales/presentation/support/sales_checkout_attempt_factory.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:erp/features/sales/logic/sales_checkout_state.dart';

class SalesCheckoutCubit extends Cubit<SalesCheckoutState> {
  SalesCheckoutCubit({
    required this.args,
    required this.repository,
    required this.session,
    required this.activeStoreContext,
    this.debounceDuration = const Duration(milliseconds: 250),
    SalesCheckoutAttemptFactory? attemptFactory,
    this.recoveryBackoff = const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ],
    Future<void> Function(Duration)? delay,
  }) : attemptFactory = attemptFactory ?? SalesCheckoutAttemptFactory(),
       delay = delay ?? Future<void>.delayed,
       super(
         SalesCheckoutState(
           status: SalesCheckoutStatus.ready,
           vm: SalesCheckoutVm(
             runtimeDraftId: args.runtimeDraftId,
             provisionalTotalAmountMinor: args.provisionalTotalAmountMinor,
             customerName: args.customerDisplayName,
             customerPhone: args.customerPhone,
             isWalkIn: args.isWalkIn,
             cashPaidMinor: args.provisionalTotalAmountMinor,
             bankPaidMinor: 0,
             note: args.orderNote,
           ),
         ),
       );

  final SalesCheckoutDraftArgs args;
  final SalesCheckoutRepository repository;
  final SessionController session;
  final ISalesActiveStoreContext activeStoreContext;
  final Duration debounceDuration;
  final SalesCheckoutAttemptFactory attemptFactory;
  final List<Duration> recoveryBackoff;
  final Future<void> Function(Duration) delay;

  bool _finalizeStarting = false;

  Future<void> load() async {}

  Future<void> retryPrecheck() => precheckNow();

  Future<void> precheckNow() async {
    await _runPrecheck();
  }

  void selectPaymentMode(SalesPaymentMode mode) {
    if (_attemptBusy) return;
    final total = state.vm.displayedTotalAmountMinor;
    var cash = state.vm.cashPaidMinor;
    var bank = state.vm.bankPaidMinor;
    if (mode == SalesPaymentMode.cash) {
      cash = total;
      bank = 0;
    } else if (mode == SalesPaymentMode.bankTransfer) {
      cash = 0;
      bank = total;
    } else if (cash == 0 && bank == 0) {
      cash = total >= 2000000 ? 2000000 : total;
      bank = total - cash;
    }
    _applyPaymentEdit(
      state.vm.copyWith(
        paymentMode: mode,
        cashPaidMinor: cash,
        bankPaidMinor: bank,
        clearDueDate: mode == SalesPaymentMode.mixed,
      ),
    );
  }

  void updateCashAmount(int amountMinor) {
    if (_attemptBusy) return;
    var safe = amountMinor < 0 ? 0 : amountMinor;
    if (state.vm.isWalkIn && state.vm.paymentMode == SalesPaymentMode.cash) {
      safe = state.vm.displayedTotalAmountMinor;
    }
    final nextVm = state.vm.copyWith(cashPaidMinor: safe);
    _applyPaymentEdit(
      nextVm.remainingReceivableMinor == 0 ? nextVm.copyWith(clearDueDate: true) : nextVm,
    );
  }

  void updateBankAmount(int amountMinor) {
    if (_attemptBusy) return;
    var safe = amountMinor < 0 ? 0 : amountMinor;
    if (state.vm.isWalkIn && state.vm.paymentMode == SalesPaymentMode.bankTransfer) {
      safe = state.vm.displayedTotalAmountMinor;
    }
    final nextVm = state.vm.copyWith(bankPaidMinor: safe);
    _applyPaymentEdit(
      nextVm.remainingReceivableMinor == 0 ? nextVm.copyWith(clearDueDate: true) : nextVm,
    );
  }

  void selectPercent(int percent) {
    if (_attemptBusy) return;
    if (state.vm.isWalkIn && percent != 100) return;
    final total = state.vm.displayedTotalAmountMinor;
    final amount = ((total * percent) / 100).round();
    switch (state.vm.paymentMode) {
      case SalesPaymentMode.cash:
        updateCashAmount(amount);
      case SalesPaymentMode.bankTransfer:
        updateBankAmount(amount);
      case SalesPaymentMode.mixed:
        // mixed giữ 2 ô nhập riêng; không map percent trực tiếp.
        return;
    }
  }

  void updateTransactionCode(String code) {
    if (_attemptBusy) return;
    _applyPaymentEdit(
      state.vm.copyWith(transactionCode: code.trim()),
    );
  }

  void updateDueDate(DateTime date) {
    if (_attemptBusy) return;
    emit(
      state.copyWith(
        vm: state.vm.copyWith(dueDate: date),
        status: SalesCheckoutStatus.ready,
        clearPrecheck: true,
        clearErrorMessage: true,
      ),
    );
  }

  void updateNote(String note) {
    if (_attemptBusy) return;
    emit(
      state.copyWith(
        vm: state.vm.copyWith(note: note),
      ),
    );
  }

  void _applyPaymentEdit(SalesCheckoutVm nextVm) {
    final revision = state.requestRevision + 1;
    emit(
      state.copyWith(
        vm: nextVm.copyWith(clearBackendGrandTotalMinor: true),
        status: SalesCheckoutStatus.ready,
        requestRevision: revision,
        clearPrecheck: true,
        clearErrorMessage: true,
      ),
    );
  }

  bool get _attemptBusy =>
      state.attemptStatus == SalesCheckoutAttemptStatus.submitting ||
      state.attemptStatus == SalesCheckoutAttemptStatus.recovering;

  Future<void> finalizeCheckout() async {
    if (state.attemptStatus != SalesCheckoutAttemptStatus.idle || _finalizeStarting) {
      return;
    }
    if (!state.vm.canFinalizePayment) return;
    _finalizeStarting = true;
    try {
      final precheckPassed = await _runPrecheck();
      if (!precheckPassed || isClosed) return;

      final tenantId = await session.requireTenantId();
      final actorId = await session.requireUserId();
      final storeId = await activeStoreContext.requireActiveStoreId();
      final envelope = attemptFactory.create(
        args: args,
        vm: state.vm,
        tenantId: tenantId,
        actorId: actorId,
        storeId: storeId,
        correlationId: session.correlationId,
      );
      emit(
        state.copyWith(
          attemptStatus: SalesCheckoutAttemptStatus.submitting,
          attempt: envelope,
          clearCheckoutResult: true,
          clearAttemptErrorMessage: true,
        ),
      );
      await _executeAttempt(envelope);
    } finally {
      _finalizeStarting = false;
    }
  }

  Future<void> retryCurrentAttempt() async {
    final envelope = state.attempt;
    if (envelope == null || _attemptBusy) return;
    emit(
      state.copyWith(
        attemptStatus: SalesCheckoutAttemptStatus.submitting,
        clearAttemptErrorMessage: true,
      ),
    );
    await _executeAttempt(envelope);
  }

  Future<void> checkAttemptAgain() async {
    if (state.attempt == null || _attemptBusy) return;
    await _recoverAttempt(state.attempt!, automatic: false);
  }

  Future<void> _executeAttempt(SalesCheckoutAttemptEnvelope envelope) async {
    try {
      final result = await repository.finalize(envelope.request);
      await _classifyResult(result, envelope);
    } on AppException catch (error) {
      if (error.code == SalesCheckoutErrorCodes.uncertainResult) {
        await _recoverAttempt(envelope, automatic: true);
      } else if (error.code == SalesCheckoutErrorCodes.idempotencyConflict) {
        emit(
          state.copyWith(
            attemptStatus: SalesCheckoutAttemptStatus.conflict,
            attemptErrorMessage: 'Yêu cầu hoàn tất xung đột. Vui lòng tải lại đơn.',
          ),
        );
      } else if (error.code == SalesCheckoutErrorCodes.staleVersion) {
        emit(
          state.copyWith(
            status: SalesCheckoutStatus.blocked,
            attemptStatus: SalesCheckoutAttemptStatus.failure,
            attemptErrorMessage: 'Dữ liệu đơn đã thay đổi. Vui lòng tải lại.',
            clearPrecheck: true,
            clearAttempt: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            attemptStatus: SalesCheckoutAttemptStatus.failure,
            attemptErrorMessage: _attemptMessageFor(error),
          ),
        );
      }
    } catch (_) {
      await _recoverAttempt(envelope, automatic: true);
    }
  }

  Future<void> _classifyResult(
    CheckoutResultDto result,
    SalesCheckoutAttemptEnvelope envelope,
  ) async {
    switch (result.status) {
      case CheckoutResultStatus.succeeded:
        emit(
          state.copyWith(
            attemptStatus: SalesCheckoutAttemptStatus.succeeded,
            checkoutResult: result,
            clearAttemptErrorMessage: true,
          ),
        );
      case CheckoutResultStatus.blocked:
        emit(
          state.copyWith(
            status: SalesCheckoutStatus.blocked,
            attemptStatus: SalesCheckoutAttemptStatus.blocked,
            checkoutResult: result,
            attemptErrorMessage: switch (result.blockedCode) {
              'PRICE_CHANGED' => 'Giá đã thay đổi. Vui lòng quay lại đơn để cập nhật giá.',
              'PRICING_BLOCKED' => 'Không xác định được giá sản phẩm. Vui lòng quay lại đơn.',
              'CUSTOMER_INVALID' => 'Khách hàng không còn hoạt động.',
              'RECEIVABLE_DUE_DATE_INVALID' => 'Ngày hẹn thanh toán không được trước hôm nay.',
              'INSUFFICIENT_STOCK' => result.blockedMessage ?? 'Không đủ tồn kho để bán.',
              _ => null,
            },
            clearAttemptErrorMessage: result.blockedCode == null,
            clearPrecheck: true,
            clearAttempt: true,
          ),
        );
      case CheckoutResultStatus.failed:
        emit(
          state.copyWith(
            attemptStatus: SalesCheckoutAttemptStatus.failure,
            checkoutResult: result,
            attemptErrorMessage: 'Không thể hoàn tất đơn.',
          ),
        );
      case CheckoutResultStatus.processing || CheckoutResultStatus.uncertain:
        await _recoverAttempt(envelope, automatic: true);
    }
  }

  Future<void> _recoverAttempt(
    SalesCheckoutAttemptEnvelope envelope, {
    required bool automatic,
  }) async {
    emit(
      state.copyWith(
        attemptStatus: SalesCheckoutAttemptStatus.recovering,
        clearAttemptErrorMessage: true,
      ),
    );
    final intervals = automatic ? recoveryBackoff : const [Duration.zero];
    for (final interval in intervals) {
      await delay(interval);
      try {
        final request = envelope.request;
        final result = await repository.getResult(
          storeId: request.storeId,
          idempotencyKey: request.idempotencyKey,
        );
        if (result.status == CheckoutResultStatus.succeeded) {
          emit(
            state.copyWith(
              attemptStatus: SalesCheckoutAttemptStatus.succeeded,
              checkoutResult: result,
            ),
          );
          return;
        }
        if (result.status == CheckoutResultStatus.blocked ||
            result.status == CheckoutResultStatus.failed) {
          await _classifyResult(result, envelope);
          return;
        }
      } on AppException catch (error) {
        if (error.code != SalesCheckoutErrorCodes.checkoutResultNotFound &&
            error.code != SalesCheckoutErrorCodes.dependencyUnavailable &&
            error.code != SalesCheckoutErrorCodes.networkError) {
          emit(
            state.copyWith(
              attemptStatus: SalesCheckoutAttemptStatus.failure,
              attemptErrorMessage: _attemptMessageFor(error),
            ),
          );
          return;
        }
      } catch (_) {}
    }
    emit(
      state.copyWith(
        attemptStatus: SalesCheckoutAttemptStatus.failure,
        attemptErrorMessage:
            'Chưa xác định được kết quả. Hãy kiểm tra lại hoặc thử lại cùng yêu cầu.',
      ),
    );
  }

  String _attemptMessageFor(AppException error) => salesCheckoutErrorMessage(
    error,
    fallback: 'Không thể hoàn tất đơn.',
    overrides: const {
      SalesCheckoutErrorCodes.noPermission: 'Bạn không còn quyền hoàn tất đơn.',
    },
  );

  Future<bool> _runPrecheck({int? forRevision}) async {
    final revision = forRevision ?? state.requestRevision + 1;
    if (forRevision == null) {
      emit(
        state.copyWith(
          status: SalesCheckoutStatus.prechecking,
          requestRevision: revision,
          clearErrorMessage: true,
        ),
      );
    } else if (isClosed || revision != state.requestRevision) {
      return false;
    }

    final vm = state.vm;

    try {
      final storeId = await activeStoreContext.requireActiveStoreId();
      final result = await repository.precheck(
        storeId: storeId,
        customerId: args.customerId,
        currencyCode: args.currencyCode,
        paymentDueDate: vm.dueDate == null
            ? null
            : DateTime(vm.dueDate!.year, vm.dueDate!.month, vm.dueDate!.day),
        lines: args.lines,
        paymentIntents: _paymentIntents(vm),
        expectedSourceVersion: args.expectedSourceVersion,
      );

      if (isClosed || revision != state.requestRevision) return false;

      final isReady = result.canFinalize && result.blockers.isEmpty;
      emit(
        state.copyWith(
          status: isReady ? SalesCheckoutStatus.ready : SalesCheckoutStatus.blocked,
          precheck: result,
          clearErrorMessage: true,
          vm: state.vm.copyWith(
            backendGrandTotalMinor: result.monetarySummary.grandTotal.amountMinor,
          ),
        ),
      );
      return isReady;
    } catch (error) {
      if (isClosed || revision != state.requestRevision) return false;
      emit(
        state.copyWith(
          status: SalesCheckoutStatus.failure,
          errorMessage: _messageFor(error),
          clearPrecheck: true,
          vm: state.vm.copyWith(clearBackendGrandTotalMinor: true),
        ),
      );
      return false;
    }
  }

  List<PaymentIntentInput> _paymentIntents(SalesCheckoutVm vm) => [
    if (vm.cashPaidMinor > 0)
      PaymentIntentInput(
        method: SalesPaymentMethod.cash,
        amount: MoneyDto(
          amountMinor: vm.cashPaidMinor,
          currencyCode: args.currencyCode,
        ),
      ),
    if (vm.bankPaidMinor > 0)
      PaymentIntentInput(
        method: SalesPaymentMethod.manualBankTransfer,
        amount: MoneyDto(
          amountMinor: vm.bankPaidMinor,
          currencyCode: args.currencyCode,
        ),
        reference: _trimToNull(vm.transactionCode),
      ),
  ];

  String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _messageFor(Object error) {
    const unavailable = 'Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.';
    return salesCheckoutErrorMessage(
      error,
      fallback: 'Không thể kiểm tra thanh toán. Vui lòng thử lại.',
      overrides: const {
        SalesCheckoutErrorCodes.noPermission: 'Bạn không còn quyền kiểm tra thanh toán.',
        SalesCheckoutErrorCodes.staleVersion:
            'Dữ liệu đơn đã thay đổi. Vui lòng quay lại kiểm tra.',
        SalesCheckoutErrorCodes.dependencyUnavailable: unavailable,
        SalesCheckoutErrorCodes.networkError: unavailable,
      },
    );
  }
}
