import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_error_codes.dart';
import '../data/partner_repository.dart';
import 'partner_error_messages.dart';
import 'partner_status_submit_state.dart';

final class PartnerStatusCubit extends Cubit<PartnerStatusSubmitState> {
  PartnerStatusCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerStatusSubmitState());

  static const deactivateSuccessMessage = 'Đã ngừng hoạt động KH & NCC.';
  static const reactivateSuccessMessage = 'Đã kích hoạt lại KH & NCC.';
  static const softDeleteSuccessMessage = 'Đã xóa hồ sơ KH & NCC.';

  final PartnerRepository _repository;

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
      final normalized = reason?.trim();
      await _repository.deactivate(
        partnerId,
        expectedVersion: expectedVersion,
        reason: (normalized == null || normalized.isEmpty) ? null : normalized,
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: deactivateSuccessMessage,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapFailure(
            error,
            fallback: 'Không thể ngừng hoạt động. Vui lòng thử lại.',
          ),
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
      final normalized = reason?.trim();
      await _repository.reactivate(
        partnerId,
        expectedVersion: expectedVersion,
        reason: (normalized == null || normalized.isEmpty) ? null : normalized,
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: reactivateSuccessMessage,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapFailure(
            error,
            fallback: 'Không thể kích hoạt lại. Vui lòng thử lại.',
          ),
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
      final normalized = reason?.trim();
      await _repository.softDelete(
        partnerId,
        expectedVersion: expectedVersion,
        reason: (normalized == null || normalized.isEmpty) ? null : normalized,
      );
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.success,
          successMessage: softDeleteSuccessMessage,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PartnerStatusSubmitStatus.failure,
          generalError: _mapDeleteFailure(error),
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

  /// Mã đã có câu riêng giữ nguyên; mã lạ → [fallback] của thao tác (Q2).
  static String _mapFailure(Object error, {required String fallback}) {
    return partnerErrorMessage(
      error,
      fallback: fallback,
      noPermission: 'Bạn không có quyền thay đổi trạng thái hồ sơ.',
    );
  }

  static String _mapDeleteFailure(Object error) {
    final code = error is AppException ? error.code : null;
    return switch (code) {
      PartnerErrorCodes.hasTransactions =>
        'Hồ sơ đã phát sinh giao dịch nên không thể xóa. Bạn có thể ngừng hoạt động.',
      PartnerErrorCodes.invalidStatus => 'Trạng thái hồ sơ không cho phép xóa.',
      _ => partnerErrorMessage(
        error,
        fallback: 'Không thể xóa hồ sơ. Vui lòng thử lại.',
        noPermission: 'Bạn không có quyền xóa hồ sơ.',
      ),
    };
  }
}
