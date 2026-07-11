import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

/// Field-level validation for transform step-one organization draft.
abstract final class PartnerTransformStepOneValidator {
  static const organizationTypeRequired = 'Vui lòng chọn loại tổ chức';
  static const organizationNameRequired = 'Vui lòng nhập tên tổ chức';
  static const phoneInvalid = 'Số điện thoại không hợp lệ';
  static const taxCodeInvalid = 'MST phải có 10 hoặc 13 chữ số';

  static Map<String, String> validate({
    required OrganizationType? organizationType,
    required String organizationName,
    required String phone,
    required String email,
    required String taxCode,
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
    if (!VEmailValidator.isValid(email)) {
      errors['email'] = VEmailValidator.defaultInvalidEmailMessage;
    }
    if (!_isValidTaxCode(taxCode)) {
      errors['taxCode'] = taxCodeInvalid;
    }
    return errors;
  }

  static bool _isValidPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[0-9]{8,15}$').hasMatch(trimmed);
  }

  static bool _isValidTaxCode(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty || RegExp(r'^[0-9]{10}([0-9]{3})?$').hasMatch(trimmed);
  }
}
