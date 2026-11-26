import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/account_repository.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure_mapper.dart';
import 'my_account_state.dart';

final class MyAccountCubit extends Cubit<MyAccountState> {
  MyAccountCubit({
    required AccountRepository accountRepository,
    required SessionController session,
  }) : _accountRepository = accountRepository,
       _session = session,
       super(const MyAccountState());

  final AccountRepository _accountRepository;
  final SessionController _session;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
      ),
    );

    try {
      final profile = await _accountRepository.getMyAccount();
      if (isClosed) return;

      var isOwner = false;
      try {
        final currentTenantId = _session.tenantId?.trim() ?? '';
        if (currentTenantId.isNotEmpty) {
          isOwner = _session.isOwner;
        } else {
          await _session.loadAccessibleTenants();
          isOwner = _session.state.tenants.any((tenant) => tenant.isOwner);
        }
      } catch (_) {
        // Không chặn trang cá nhân nếu danh sách tổ chức lỗi.
      }
      if (isClosed) return;

      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          profile: profile,
          isOwner: isOwner,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }
}
