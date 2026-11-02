import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/partner_error_codes.dart';
import '../data/models/partner_inputs.dart';
import '../data/partner_repository.dart';
import '../presentation/widgets/partner_transform_blocked_state.dart';
import 'partner_transform_submit_state.dart';

final class PartnerTransformCubit extends Cubit<PartnerTransformSubmitState> {
  PartnerTransformCubit({required PartnerRepository repository})
    : _repository = repository,
      super(const PartnerTransformSubmitState());

  static const duplicateUserMessage =
      'Đã tồn tại hồ sơ trùng SĐT/email/MST. Vui lòng kiểm tra lại.';

  static const duplicatePhoneMessage = 'Số điện thoại đã tồn tại trên hồ sơ khác.';
  static const duplicateEmailMessage = 'Email đã tồn tại trên hồ sơ khác.';
  static const duplicateTaxCodeMessage = 'MST đã tồn tại trên hồ sơ khác.';
  static const duplicateNameMessage = 'Tên tổ chức đã tồn tại trên hồ sơ khác.';

  final PartnerRepository _repository;

  static const _failureMessage = 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.';

  Future<void> confirmTransform({
    required String partnerId,
    required int expectedVersion,
    required OrganizationProfileInput organizationProfile,
    bool confirmDuplicate = false,
  }) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        status: PartnerTransformSubmitStatus.submitting,
        clearBlocked: true,
        clearGeneralError: true,
        clearFieldErrors: true,
      ),
    );

    try {
      final transformedId = await _repository.transformToOrganization(
        partnerId: partnerId,
        expectedVersion: expectedVersion,
        organizationProfile: organizationProfile,
        confirmDuplicate: confirmDuplicate,
      );
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.success,
          transformedPartnerId: transformedId,
        ),
      );
    } on AppException catch (error) {
      _mapBlocked(error);
    } catch (_) {
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.failure,
          generalError: _failureMessage,
        ),
      );
    }
  }

  void _mapBlocked(AppException error) {
    if (error.code == PartnerErrorCodes.primaryContactOfOrganization) {
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.failure,
          generalError:
              'Hồ sơ này đang là người liên hệ chính của một tổ chức nên không thể chuyển đổi.',
        ),
      );
      return;
    }
    if (error.code == PartnerErrorCodes.duplicateWarning) {
      _emitDuplicate(error.serverMessage ?? '');
      return;
    }

    final blocked = partnerTransformBlockedKindFromCode(error.code);
    if (blocked != null) {
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.blocked,
          blocked: blocked,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PartnerTransformSubmitStatus.failure,
        generalError: _failureMessage,
      ),
    );
  }

  void _emitDuplicate(String raw) {
    emit(
      state.copyWith(
        status: PartnerTransformSubmitStatus.duplicate,
        generalError: duplicateUserMessage,
        fieldErrors: parseDuplicateFieldErrors(raw),
      ),
    );
  }

  void clearBlocked() {
    emit(
      state.copyWith(
        status: PartnerTransformSubmitStatus.idle,
        clearBlocked: true,
        clearGeneralError: true,
        clearFieldErrors: true,
      ),
    );
  }

  /// Maps RPC duplicate payload fields → form error keys.
  static Map<String, String> parseDuplicateFieldErrors(String raw) {
    final matched = <String>{};
    for (final pattern in [
      RegExp(r'"field"\s*:\s*"([^"]+)"', caseSensitive: false),
      RegExp(r'"matched_field"\s*:\s*"([^"]+)"', caseSensitive: false),
    ]) {
      for (final match in pattern.allMatches(raw)) {
        matched.add(match.group(1)!.toLowerCase());
      }
    }

    // Fallback when payload has no field (still treat as phone — most common).
    if (matched.isEmpty && _looksLikeDuplicate(raw)) {
      matched.add('phone');
    }

    final errors = <String, String>{};
    for (final field in matched) {
      switch (field) {
        case 'phone':
          errors['phone'] = duplicatePhoneMessage;
        case 'email':
          errors['email'] = duplicateEmailMessage;
        case 'tax_code':
        case 'taxcode':
          errors['taxCode'] = duplicateTaxCodeMessage;
        case 'name':
        case 'organization_name':
          errors['organizationName'] = duplicateNameMessage;
      }
    }
    return errors;
  }

  static bool _looksLikeDuplicate(String raw) =>
      raw.toUpperCase().contains(PartnerErrorCodes.duplicateWarning);
}
