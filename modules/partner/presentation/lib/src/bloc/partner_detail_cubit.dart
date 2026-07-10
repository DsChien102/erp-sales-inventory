import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_detail_state.dart';

class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  PartnerDetailCubit({
    required String partnerId,
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerId = partnerId,
       _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(const PartnerDetailInitial());

  final String _partnerId;
  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    emit(const PartnerDetailLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(tenantId: tenantId, partnerId: _partnerId),
      );
      emit(PartnerDetailLoaded(detail: detail));
    } catch (error) {
      emit(PartnerDetailError(error.toString()));
    }
  }

  void selectTab(int index) {
    final current = state;
    if (current is! PartnerDetailLoaded) return;
    emit(current.copyWith(selectedTabIndex: index));
  }
}
