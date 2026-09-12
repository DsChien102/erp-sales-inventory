import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

/// Field-level validation for transform step-one organization draft.
abstract final class PartnerTransformStepOneValidator {
  static const organizationTypeRequired = 'Vui lòng chọn loại tổ chức';
  static const organizationNameRequired = 'Vui lòng nhập tên tổ chức';
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
    final phoneError = VPhoneValidator.validate(phone, isRequired: true);
    if (phoneError != null) {
      errors['phone'] = phoneError;
    }
    if (!VEmailValidator.isValid(email)) {
      errors['email'] = VEmailValidator.defaultInvalidEmailMessage;
    }
    if (!_isValidTaxCode(taxCode)) {
      errors['taxCode'] = taxCodeInvalid;
    }
    return errors;
  }

  static bool _isValidTaxCode(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty || RegExp(r'^[0-9]{10}([0-9]{3})?$').hasMatch(trimmed);
  }
}
