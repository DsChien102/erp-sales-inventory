import 'package:vet45_partner_domain/domain.dart';

/// Field-level validation for transform step-one organization draft.
abstract final class PartnerTransformStepOneValidator {
  static const organizationTypeRequired = 'Vui lòng chọn loại tổ chức';
  static const organizationNameRequired = 'Vui lòng nhập tên tổ chức';
  static const phoneInvalid = 'Số điện thoại không hợp lệ';

  static Map<String, String> validate({
    required OrganizationType? organizationType,
    required String organizationName,
    required String phone,
  }) {
    final errors = <String, String>{};
    if (organizationType == null) {
      errors['organizationType'] = organizationTypeRequired;
    }
    if (organizationName.trim().isEmpty) {
      errors['organizationName'] = organizationNameRequired;
    }
    if (!_isValidPhone(phone)) {
      errors['phone'] = phoneInvalid;
    }
    return errors;
  }

  static bool _isValidPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (!RegExp(r'^\+?[0-9\s.\-()]+$').hasMatch(trimmed)) return false;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }
}
