import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_detail_state.dart';

final class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  PartnerDetailCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(const PartnerDetailInitial());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> loadDetail(String partnerId) async {
    emit(const PartnerDetailLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: partnerId,
        ),
      );
      emit(PartnerDetailLoaded(result));
    } catch (e) {
      final errorStr = e.toString();
      final isNotFound = errorStr.contains('NOT_FOUND') || errorStr.contains('not found');
      final isNoPermission = errorStr.contains('NO_PERMISSION') || errorStr.contains('permission denied');
      emit(PartnerDetailError(
        errorStr,
        isNotFound: isNotFound,
        isNoPermission: isNoPermission,
      ));
    }
  }

  void selectTab(int index) {
    final currentState = state;
    if (currentState is PartnerDetailLoaded) {
      emit(PartnerDetailLoaded(
        currentState.detail,
        selectedTabIndex: index,
      ));
    }
  }
}
