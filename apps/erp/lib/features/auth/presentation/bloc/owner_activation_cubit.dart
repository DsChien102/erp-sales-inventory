import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../data/owner_activation_client.dart';
import 'owner_activation_state.dart';

final _log = Logger('erp.owner_activation.cubit');

/// Owner account activation (Hướng 1): inspect the emailed code, then sign up +
/// accept (creates the owner account + membership). Never exposes code/password.
final class OwnerActivationCubit extends Cubit<OwnerActivationState> {
  OwnerActivationCubit({
    required OwnerActivationClient client,
    required String idempotencyKey,
  }) : _client = client,
       _idempotencyKey = idempotencyKey,
       super(const OwnerActivationState());

  final OwnerActivationClient _client;
  final String _idempotencyKey;

  Future<void> submit({required String code, required String password}) async {
    if (isClosed) return;
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty || password.isEmpty) {
      emit(
        state.copyWith(
          step: OwnerActivationStep.failed,
          errorMessage: 'Vui lòng nhập mã kích hoạt và mật khẩu.',
        ),
      );
      return;
    }
    if (password.length < 8) {
      emit(
        state.copyWith(
          step: OwnerActivationStep.failed,
          errorMessage: 'Mật khẩu phải có tối thiểu 8 ký tự.',
        ),
      );
      return;
    }

    emit(state.copyWith(step: OwnerActivationStep.submitting, clearError: true));
    try {
      final inspection = await _client.inspect(trimmedCode);
      if (!inspection.valid || inspection.email == null) {
        _fail();
        return;
      }
      await _client.activate(
        code: trimmedCode,
        email: inspection.email!,
        password: password,
        accountExists: inspection.accountExists,
        givenName: inspection.givenName,
        familyName: inspection.familyName,
        phone: inspection.phone,
        idempotencyKey: _idempotencyKey,
      );
      if (isClosed) return;
      emit(state.copyWith(step: OwnerActivationStep.activated, clearError: true));
    } catch (error, stackTrace) {
      _log.warning('Owner activation submit failed', error, stackTrace);
      _fail();
    }
  }

  void _fail() {
    if (isClosed) return;
    emit(
      state.copyWith(
        step: OwnerActivationStep.failed,
        errorMessage: 'Kích hoạt không thành công. Vui lòng kiểm tra mã và thử lại.',
      ),
    );
  }
}
