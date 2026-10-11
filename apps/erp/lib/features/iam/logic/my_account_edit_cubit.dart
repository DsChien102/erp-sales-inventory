import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../data/account_repository.dart';
import 'iam_load_status.dart';
import 'iam_ui_failure.dart';
import 'iam_ui_failure_mapper.dart';
import 'my_account_edit_state.dart';

final class MyAccountEditCubit extends Cubit<MyAccountEditState> {
  MyAccountEditCubit({required AccountRepository accountRepository})
    : _accountRepository = accountRepository,
      super(const MyAccountEditState());

  final AccountRepository _accountRepository;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
        clearSaved: true,
      ),
    );

    try {
      final profile = await _accountRepository.getMyAccount();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          profile: profile,
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

  Future<bool> save({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    if (isClosed || state.isSubmitting) return false;
    emit(state.copyWith(isSubmitting: true, clearFailure: true, clearSaved: true));

    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: firstName.trim().isEmpty ? 'firstName is required' : 'lastName is required',
          ),
        ),
      );
      return false;
    }

    try {
      final saved = await _accountRepository.updateMyAccount(
        avatarReference: avatarUrl,
        givenName: firstName,
        familyName: lastName,
        phone: phoneNumber,
      );
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSubmitting: false,
          profile: saved,
          savedProfile: saved,
          clearFailure: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailureMapper.from(error),
        ),
      );
      return false;
    }
  }
}
