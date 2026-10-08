import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../core/iam/iam_load_status.dart';
import '../../../core/iam/iam_ui_failure.dart';
import '../../../core/iam/iam_ui_failure_mapper.dart';
import '../../../core/session/session_controller.dart';
import '../../iam/data/organization_repository.dart';
import 'iam_feature_access_state.dart';

final class IamFeatureAccessCubit extends Cubit<IamFeatureAccessState> {
  IamFeatureAccessCubit({
    required SessionController session,
    required OrganizationRepository organizations,
  }) : _session = session,
       _organizations = organizations,
       super(const IamFeatureAccessState());

  final SessionController _session;
  final OrganizationRepository _organizations;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        readinessStatus: IamLoadStatus.loading,
        clearFailure: true,
        clearReadiness: true,
      ),
    );

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
          readinessStatus: IamLoadStatus.initial,
          clearFailure: true,
          clearReadiness: true,
        ),
      );

      final tenantId = session.tenantId;
      if (tenantId != null && tenantId.isNotEmpty && state.canViewReadiness) {
        emit(state.copyWith(readinessStatus: IamLoadStatus.loading));
        try {
          final readiness = await _organizations.getReadiness();
          if (isClosed) return;
          emit(
            state.copyWith(
              readinessStatus: IamLoadStatus.success,
              readiness: readiness,
            ),
          );
        } catch (_) {
          if (isClosed) return;
          emit(
            state.copyWith(
              readinessStatus: IamLoadStatus.failure,
              clearReadiness: true,
            ),
          );
        }
      }
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
