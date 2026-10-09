import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../core/iam/iam_load_status.dart';
import '../../../core/iam/iam_ui_failure.dart';
import '../../../core/iam/iam_ui_failure_mapper.dart';
import '../../../core/session/session_controller.dart';
import 'iam_feature_access_state.dart';

final class IamFeatureAccessCubit extends Cubit<IamFeatureAccessState> {
  IamFeatureAccessCubit({required SessionController session})
    : _session = session,
      super(const IamFeatureAccessState());

  final SessionController _session;

  Future<void> load() async {
    emit(state.copyWith(status: IamLoadStatus.loading, clearFailure: true));

    try {
      final session = _session.readSession();
      if (!session.isAuthenticated) {
        emit(
          state.copyWith(
            status: IamLoadStatus.unauthorized,
            session: session,
            failure: const IamUiFailure(
              code: IamBlockedCodes.authenticationRequired,
              message: 'Bạn cần đăng nhập lại.',
            ),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          session: session,
          clearFailure: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: IamLoadStatus.failure,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }
}
