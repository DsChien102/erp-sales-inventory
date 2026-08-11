import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import 'my_account_edit_state.dart';

final class MyAccountEditCubit extends Cubit<MyAccountEditState> {
  MyAccountEditCubit({required IIamModule iamModule})
    : _iamModule = iamModule,
      super(const MyAccountEditState());

  final IIamModule _iamModule;

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
      final profile = await _iamModule.executeQueryAsync<MyIdentityProfileDto>(
        GetMyIdentityProfileQuery(),
      );
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

    try {
      final saved = await _iamModule.executeCommandAsync<MyIdentityProfileDto>(
        UpdateMyIdentityProfileCommand(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          avatarUrl: avatarUrl,
        ),
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
