import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

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
        clearFailure: true,
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
          clearFailure: true,
          clearReadiness: true,
        ),
      );

      final tenantId = session.tenantId;
      if (tenantId != null &&
          tenantId.isNotEmpty &&
          state.canViewReadiness) {
        try {
          final readiness = await _iamModule
              .executeQueryAsync<TenantReadinessDto>(
                GetTenantReadinessQuery(tenantId: tenantId),
              );
          if (isClosed) return;
          emit(state.copyWith(readiness: readiness));
        } catch (_) {
          // Soft banner without DTO counts when readiness load fails.
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
