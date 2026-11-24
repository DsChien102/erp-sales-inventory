import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

import '../../logic/partner_create_form_validator.dart';

/// Field-level validation for transform step-one organization draft.
abstract final class PartnerTransformStepOneValidator {
  static const organizationTypeRequired = 'Vui lòng chọn loại tổ chức';
  static const organizationNameRequired = 'Vui lòng nhập tên tổ chức';
  static const taxCodeInvalid = PartnerCreateFormValidator.taxCodeInvalid;

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
    if (!PartnerCreateFormValidator.isValidTaxCode(taxCode)) {
      errors['taxCode'] = taxCodeInvalid;
    }
    return errors;
  }
}
