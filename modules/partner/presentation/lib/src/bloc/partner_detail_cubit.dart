import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../mappers/partner_ui_mapper.dart';
import '../utils/partner_presentation_errors.dart';
import 'partner_detail_state.dart';
import 'partner_list_state.dart';

class PartnerDetailCubit extends Cubit<PartnerDetailState> {
  PartnerDetailCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
    PartnerItemModel? initialPartner,
  })  : _partnerModule = partnerModule,
        _executionContext = executionContext,
        super(
          PartnerDetailState(
            partner: initialPartner,
            status: initialPartner == null
                ? PartnerDetailStatus.initial
                : PartnerDetailStatus.success,
          ),
        );

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> load(String partnerId) async {
    emit(
      state.copyWith(
        status: PartnerDetailStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _partnerModule.executeQueryAsync(
        GetPartnerDetailQuery(
          tenantId: tenantId,
          partnerId: partnerId,
        ),
      );

      if (detail == null) {
        emit(
          state.copyWith(
            status: PartnerDetailStatus.failure,
            errorMessage: 'Không tìm thấy đối tác.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: PartnerDetailStatus.success,
          partner: PartnerUiMapper.toDetailItem(detail),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerDetailStatus.failure,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }

  void setTransactionStatus(TransactionHistoryStatus status) {
    emit(state.copyWith(transactionStatus: status));
  }

  void searchTransactions(String query) {
    emit(state.copyWith(transactionSearchQuery: query));
  }
}
