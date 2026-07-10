import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/partner_transform_blocked_state.dart';
import 'partner_transform_submit_state.dart';

final class PartnerTransformCubit extends Cubit<PartnerTransformSubmitState> {
  PartnerTransformCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(const PartnerTransformSubmitState());

  static const duplicateUserMessage =
      'Đã tồn tại hồ sơ trùng SĐT/email/MST. Vui lòng kiểm tra lại.';

  static const duplicatePhoneMessage =
      'Số điện thoại đã tồn tại trên hồ sơ khác.';
  static const duplicateEmailMessage =
      'Email đã tồn tại trên hồ sơ khác.';
  static const duplicateTaxCodeMessage =
      'MST đã tồn tại trên hồ sơ khác.';
  static const duplicateNameMessage =
      'Tên tổ chức đã tồn tại trên hồ sơ khác.';

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final result = await _partnerModule.executeCommandAsync(
        TransformPersonToOrganizationCommand(
          tenantId: tenantId,
          actorId: actorId,
          partnerId: partnerId,
          organizationProfile: organizationProfile,
          expectedVersion: expectedVersion,
          confirmDuplicate: confirmDuplicate,
        ),
      );
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.success,
          transformedPartnerId: result.partnerId,
        ),
      );
    } on PartnerBlockedException catch (error) {
      _mapBlocked(error);
    } catch (error) {
      if (_looksLikeDuplicate(error.toString())) {
        _emitDuplicate(error.toString());
        return;
      }
      emit(
        state.copyWith(
          status: PartnerTransformSubmitStatus.failure,
          generalError: 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.',
        ),
      );
    }
  }

  void _mapBlocked(PartnerBlockedException error) {
    if (error.code == PartnerBlockedCodes.duplicateWarning ||
        _looksLikeDuplicate(error.message ?? '')) {
      _emitDuplicate(error.message ?? error.code);
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
        generalError: _safeUserMessage(error.message),
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
      raw.toUpperCase().contains(PartnerBlockedCodes.duplicateWarning);

  static String _safeUserMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Không thể chuyển đổi hồ sơ.';
    }
    final upper = raw.toUpperCase();
    if (upper.contains('POSTGRESTEXCEPTION') ||
        upper.contains('EXCEPTION') ||
        raw.contains('{') ||
        raw.length > 160) {
      return 'Không thể chuyển đổi hồ sơ. Vui lòng thử lại.';
    }
    return raw;
  }
}
