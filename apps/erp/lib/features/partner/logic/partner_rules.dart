import 'package:erp/core/errors/app_exception.dart';

import '../data/models/partner_enums.dart';
import '../data/models/partner_inputs.dart';

/// Rule đầu vào mà module cũ kiểm trước khi gọi RPC create / update / transform
/// (chép từ `modules/partner/domain`). Sai → [AppException] `VALIDATION_ERROR`
/// với `serverMessage` là câu của rule, không gọi RPC.
///
/// Không kiểm: người liên hệ chính (`organizationPrimaryContact`), chuyển trạng thái,
/// hồ sơ đã xoá, đúng loại khi chuyển đổi — server trả `INVALID_STATUS` / `NOT_FOUND`.
abstract final class PartnerRules {
  static final RegExp _email = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final RegExp _nonDigit = RegExp(r'\D');

  /// `PartnerMustHaveAtLeastOneRoleRule`.
  static void checkRoles(List<PartnerRoleType> roles) {
    if (roles.isEmpty) {
      _fail('Partner must have at least one role');
    }
  }

  /// `PersonOrOrganizationProfileExclusiveRule`: đúng một hồ sơ, khớp với loại.
  static void checkProfileMatchesType(
    PartnerType type, {
    PersonProfileInput? person,
    OrganizationProfileInput? organization,
  }) {
    final hasPerson = person != null;
    final hasOrganization = organization != null;
    final broken = (hasPerson && hasOrganization) ||
        switch (type) {
          PartnerType.person => !hasPerson || hasOrganization,
          PartnerType.organization => !hasOrganization || hasPerson,
        };
    if (broken) {
      _fail('Partner type must match exactly one profile (person or organization)');
    }
  }

  static void checkPersonProfile(PersonProfileInput profile) {
    _checkPhone(profile.phone);
    final phone2 = profile.phone2;
    if (phone2 != null) _checkPhone(phone2);
    _checkEmail(profile.email);
    _checkTaxCode(profile.taxCode);
    _checkEmail(profile.invoice?.invoiceEmail);
    _checkDisplayName(profile.fullName);
  }

  static void checkOrganizationProfile(OrganizationProfileInput profile) {
    _checkPhone(profile.phone);
    _checkEmail(profile.email);
    _checkTaxCode(profile.taxCode);
    _checkEmail(profile.invoice?.invoiceEmail);
    _checkDisplayName(profile.organizationName);
  }

  /// `PartnerDisplayNameMustNotBeBlankRule`.
  static void _checkDisplayName(String value) {
    if (value.trim().isEmpty) _fail('Display name must not be blank');
  }

  /// `PhoneMustNotBeBlankRule` + `PhoneFormatInvalidRule` (8–15 chữ số).
  static void _checkPhone(String raw) {
    final value = raw.trim();
    if (value.isEmpty) _fail('Phone is required');
    final digits = value.replaceAll(_nonDigit, '');
    if (digits.length < 8 || digits.length > 15) _fail('Phone format is invalid');
  }

  /// `EmailFormatInvalidRule`: null hoặc rỗng thì bỏ qua.
  static void _checkEmail(String? raw) {
    if (raw == null) return;
    final value = raw.trim();
    if (value.isEmpty) return;
    if (!_email.hasMatch(value)) _fail('Email format is invalid');
  }

  /// `TaxCodeMustNotBeBlankRule`: khác null thì không được chỉ có khoảng trắng.
  static void _checkTaxCode(String? raw) {
    if (raw == null) return;
    if (raw.trim().isEmpty) _fail('Tax code must not be blank when provided');
  }

  static Never _fail(String message) =>
      throw AppException(AppErrorCode.validation, serverMessage: message);
}
