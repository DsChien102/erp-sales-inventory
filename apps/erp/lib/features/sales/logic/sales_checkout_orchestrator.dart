import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/models/my_account.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:get_it/get_it.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:c45_shared_application/application.dart';

abstract final class SalesCheckoutOrchestrator {
  static SalesCheckoutPrepareFn bind() {
    return (SalesComposeState state) async {
      try {
        final executionContext = GetIt.instance<IExecutionContext>();
        final session = GetIt.instance<SessionController>();
        final accounts = GetIt.instance<AccountRepository>();
        final repository = GetIt.instance<SalesCheckoutRepository>();
        final tenantId = (await executionContext.requireTenantId()).trim();
        final actorId = (await executionContext.requireUserId()).trim();
        final activeStoreId = (await session.requireActiveStoreId()).trim();
        if (tenantId.isEmpty || actorId.isEmpty || activeStoreId.isEmpty) {
          throw StateError('Checkout identity context is incomplete.');
        }

        // Mã / tên cửa hàng nằm sẵn trong phiên (nạp cùng get_session_context).
        final sellerProfile = await accounts.getMyAccount();
        final storeCode = (session.activeStoreCode ?? '').trim();
        final storeDisplayName = (session.activeStoreDisplayName ?? '').trim();
        final sellerDisplayName = _sellerDisplayName(
          sellerProfile: sellerProfile,
          actorId: actorId,
        );
        if (sellerProfile.userId.trim() != actorId ||
            storeCode.isEmpty ||
            storeDisplayName.isEmpty ||
            sellerDisplayName.isEmpty) {
          throw StateError('Checkout identity context is inconsistent.');
        }

        final args = SalesCheckoutDraftArgsMapper.fromCompose(
          state,
          store: StoreSnapshotDto(
            storeId: activeStoreId,
            storeCode: storeCode,
            displayName: storeDisplayName,
          ),
          seller: ActorSnapshotDto(
            actorId: actorId,
            displayName: sellerDisplayName,
          ),
        );

        final precheck = await repository.precheck(
          storeId: activeStoreId,
          customerId: args.customerId,
          currencyCode: args.currencyCode,
          lines: args.lines,
          paymentIntents: [
            PaymentIntentInput(
              method: SalesPaymentMethod.cash,
              amount: MoneyDto(
                amountMinor: args.provisionalTotalAmountMinor,
                currencyCode: args.currencyCode,
              ),
            ),
          ],
          expectedSourceVersion: args.expectedSourceVersion,
        );
        if (!precheck.canFinalize || precheck.blockers.isNotEmpty) {
          final message = precheck.blockers.isNotEmpty
              ? precheck.blockers.first.message
              : 'Đơn chưa đủ điều kiện thanh toán.';
          return SalesCheckoutPrepareBlocked(message: message);
        }
        return SalesCheckoutPrepareReady(args);
      } catch (_) {
        return const SalesCheckoutPrepareFailed(
          message: 'Không thể xác thực hoặc kiểm tra điều kiện thanh toán. Vui lòng thử lại.',
        );
      }
    };
  }

  static String _sellerDisplayName({
    required MyAccount sellerProfile,
    required String actorId,
  }) {
    final fullName = sellerProfile.fullName.trim();
    if (fullName.isNotEmpty) return fullName;
    final email = sellerProfile.email.trim();
    if (email.isNotEmpty) return email;
    return actorId;
  }
}
