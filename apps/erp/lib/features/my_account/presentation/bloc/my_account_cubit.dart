import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

enum MyAccountLoadStatus { idle, loading, success, failure }

final class MyAccountState {
  const MyAccountState({
    this.status = MyAccountLoadStatus.idle,
    this.profile,
    this.errorMessage,
  });

  final MyAccountLoadStatus status;
  final MyAccountUiModel? profile;
  final String? errorMessage;

  MyAccountState copyWith({
    MyAccountLoadStatus? status,
    MyAccountUiModel? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyAccountState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final class MyAccountCubit extends Cubit<MyAccountState> {
  MyAccountCubit({required IIamModule iamModule})
    : _iamModule = iamModule,
      super(const MyAccountState());

  final IIamModule _iamModule;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: MyAccountLoadStatus.loading, clearError: true),
    );

    try {
      final dto = await _iamModule.executeQueryAsync<MyIdentityProfileDto>(
        GetMyIdentityProfileQuery(),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MyAccountLoadStatus.success,
          profile: MyAccountUiModel.fromDto(dto),
        ),
      );
    } on ApplicationException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MyAccountLoadStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MyAccountLoadStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void applyLocalProfile(MyAccountUiModel profile) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: MyAccountLoadStatus.success,
        profile: profile,
        clearError: true,
      ),
    );
  }
}
