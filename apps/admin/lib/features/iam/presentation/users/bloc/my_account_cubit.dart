import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import 'my_account_state.dart';

final class MyAccountCubit extends Cubit<MyAccountState> {
  MyAccountCubit({required IIamModule iamModule})
    : _iamModule = iamModule,
      super(const MyAccountState());

  final IIamModule _iamModule;

  IIamModule get iamModule => _iamModule;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
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
}
