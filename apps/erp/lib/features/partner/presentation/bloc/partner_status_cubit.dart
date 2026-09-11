import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_status_submit_state.dart';

final class PartnerStatusCubit extends Cubit<PartnerStatusSubmitState> {
  PartnerStatusCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(const PartnerStatusSubmitState());

  static const deactivateSuccessMessage = 'Đã ngừng hoạt động KH & NCC.';
  static const reactivateSuccessMessage = 'Đã kích hoạt lại KH & NCC.';
  static const softDeleteSuccessMessage = 'Đã xóa hồ sơ KH & NCC.';

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  Future<void> deactivate({
    required String partnerId,
    required int expectedVersion,
    String? reason,
  }) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        status: PartnerStatusSubmitStatus.submitting,
        clearGeneralError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final normalized = reason?.trim();
      await _partnerModule.executeCommandAsync(
        DeactivatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          reason: (normalized == null || normalized.isEmpty) ? null : normalized,
          expectedVersion: expectedVersion,
        ),
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: deactivateSuccessMessage,
        ),
      );
    } on PartnerBlockedException catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapBlocked(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: 'Không thể ngừng hoạt động. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> reactivate({
    required String partnerId,
    required int expectedVersion,
    String? reason,
  }) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        status: PartnerStatusSubmitStatus.submitting,
        clearGeneralError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final normalized = reason?.trim();
      await _partnerModule.executeCommandAsync(
        ReactivatePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          reason: (normalized == null || normalized.isEmpty) ? null : normalized,
          expectedVersion: expectedVersion,
        ),
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: reactivateSuccessMessage,
        ),
      );
    } on PartnerBlockedException catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapBlocked(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: 'Không thể kích hoạt lại. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> softDelete({
    required String partnerId,
    required int expectedVersion,
    String? reason,
  }) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        status: PartnerStatusSubmitStatus.submitting,
        clearGeneralError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final normalized = reason?.trim();
      await _partnerModule.executeCommandAsync(
        SoftDeletePartnerCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          reason: (normalized == null || normalized.isEmpty) ? null : normalized,
          expectedVersion: expectedVersion,
        ),
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: softDeleteSuccessMessage,
        ),
      );
    } on PartnerBlockedException catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapDeleteBlocked(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: 'Không thể xóa hồ sơ. Vui lòng thử lại.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        status: PartnerStatusSubmitStatus.idle,
        clearGeneralError: true,
        clearSuccessMessage: true,
      ),
    );
  }

  static String _mapBlocked(PartnerBlockedException error) {
    return switch (error.code) {
      PartnerBlockedCodes.noPermission =>
        'Bạn không có quyền thay đổi trạng thái hồ sơ.',
      PartnerBlockedCodes.stateChanged =>
        'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại.',
      PartnerBlockedCodes.invalidStatus =>
        'Trạng thái hồ sơ không cho phép thao tác này.',
      PartnerBlockedCodes.notFound => 'Không tìm thấy hồ sơ.',
      _ => error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Không thể thay đổi trạng thái. Vui lòng thử lại.',
    };
  }

  static String _mapDeleteBlocked(PartnerBlockedException error) {
    return switch (error.code) {
      PartnerBlockedCodes.noPermission =>
        'Bạn không có quyền xóa hồ sơ.',
      PartnerBlockedCodes.stateChanged =>
        'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại.',
      PartnerBlockedCodes.hasTransactions =>
        'Hồ sơ đã phát sinh giao dịch nên không thể xóa. Anh có thể ngừng hoạt động.',
      PartnerBlockedCodes.invalidStatus =>
        'Trạng thái hồ sơ không cho phép xóa.',
      PartnerBlockedCodes.notFound => 'Không tìm thấy hồ sơ.',
      _ => error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'Không thể xóa hồ sơ. Vui lòng thử lại.',
    };
  }
}
