
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
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
  }) : _partnerModule = partnerModule,
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
        clearStatusChangeMessage: true,
        clearDeleteMessage: true,
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
          hasBusinessData: detail.hasBusinessData,
        ),
      );
      await loadTransactionHistory(partnerId);
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerDetailStatus.failure,
          errorMessage: partnerErrorMessage(error),
        ),
      );
    }
  }

  Future<void> loadTransactionHistory(
    String partnerId, {
    PartnerTransactionHistoryCriteria? criteria,
  }) async {
    emit(state.copyWith(historyStatus: PartnerHistoryStatus.loading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _partnerModule.executeQueryAsync(
        GetPartnerTransactionHistoryQuery(
          tenantId: tenantId,
          partnerId: partnerId,
          criteria: criteria ?? PartnerTransactionHistoryCriteria(),
        ),
      );

      emit(
        state.copyWith(
          historyStatus: PartnerHistoryStatus.loaded,
          history: result.items,
        ),
      );
    } catch (_) {
      emit(state.copyWith(historyStatus: PartnerHistoryStatus.error));
    }
  }

  Future<bool> deactivatePartner() async {
    return _changeStatus(
      successMessage: 'Đã ngừng hoạt động đối tác.',
      commandBuilder: (tenantId, actorId, partner) =>
          PartnerUiMapper.toDeactivateCommand(
            tenantId: tenantId,
            actorId: actorId,
            partner: partner,
          ),
    );
  }

  Future<bool> reactivatePartner() async {
    return _changeStatus(
      successMessage: 'Đã kích hoạt lại đối tác.',
      commandBuilder: (tenantId, actorId, partner) =>
          PartnerUiMapper.toReactivateCommand(
            tenantId: tenantId,
            actorId: actorId,
            partner: partner,
          ),
    );
  }

  Future<bool> _changeStatus<T>({
    required String successMessage,
    required ICommand<T> Function(
      String tenantId,
      String actorId,
      PartnerItemModel partner,
    )
    commandBuilder,
  }) async {
    final partner = state.partner;
    if (partner == null || state.isChangingStatus) {
      return false;
    }

    emit(
      state.copyWith(
        isChangingStatus: true,
        clearStatusChangeMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      await _partnerModule.executeCommandAsync(
        commandBuilder(tenantId, actorId, partner),
      );

      await load(partner.id);
      emit(
        state.copyWith(
          isChangingStatus: false,
          statusChangeMessage: successMessage,
        ),
      );
      return true;
    } catch (error) {
      final message = partnerErrorMessage(error);
      if (message.contains('tải lại')) {
        await load(partner.id);
      }
      emit(
        state.copyWith(
          isChangingStatus: false,
          statusChangeMessage: message,
        ),
      );
      return false;
    }
  }

  Future<bool> deletePartner() async {
    final partner = state.partner;
    if (partner == null || state.isDeletingPartner || !state.canDelete) {
      return false;
    }

    emit(
      state.copyWith(
        isDeletingPartner: true,
        clearDeleteMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      await _partnerModule.executeCommandAsync(
        PartnerUiMapper.toDeleteCommand(
          tenantId: tenantId,
          actorId: actorId,
          partner: partner,
          hasBusinessData: state.hasBusinessData,
        ),
      );

      emit(
        state.copyWith(
          isDeletingPartner: false,
          wasDeleted: true,
          clearPartner: true,
          deleteMessage: 'Đã xóa hồ sơ đối tác.',
        ),
      );
      return true;
    } catch (error) {
      final message = partnerErrorMessage(error);
      if (message.contains('tải lại') || message.contains('giao dịch')) {
        await load(partner.id);
      }
      emit(
        state.copyWith(
          isDeletingPartner: false,
          deleteMessage: message,
        ),
      );
      return false;
    }
  }
}
