import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

import 'iam_feature_access_state.dart';

final class IamFeatureAccessCubit extends Cubit<IamFeatureAccessState> {
  IamFeatureAccessCubit({required IIamModule iamModule})
    : _iamModule = iamModule,
      super(const IamFeatureAccessState());

  final IIamModule _iamModule;

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
      final session = await _iamModule.executeQueryAsync<SessionDto>(
        GetCurrentSessionQuery(),
      );
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
          final readiness = await _iamModule.executeQueryAsync<TenantReadinessDto>(
            GetTenantReadinessQuery(tenantId: tenantId),
          );
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
