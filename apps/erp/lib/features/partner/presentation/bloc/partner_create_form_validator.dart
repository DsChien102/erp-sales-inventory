import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_create_state.dart';

/// Local form validation for create/edit partner draft.
abstract final class PartnerCreateFormValidator {
  static Map<String, String> validateAll(PartnerCreateState state) {
    final errors = <String, String>{};
    for (final section in state.sections) {
      errors.addAll(validateSection(state, section));
    }
    return errors;
  }

  static Map<String, String> validateSection(
    PartnerCreateState state,
    PartnerCreateSection section,
  ) {
    final errors = <String, String>{};
    switch (section) {
      case PartnerCreateSection.role:
        if (state.roles.isEmpty) {
          errors['roles'] = 'Vui lòng chọn vai trò giao dịch';
        }
      case PartnerCreateSection.main:
        if (state.partnerType == PartnerType.person &&
            state.fullName.trim().isEmpty) {
          errors['fullName'] = 'Vui lòng nhập họ và tên';
        }
        if (state.partnerType == PartnerType.organization &&
            state.organizationName.trim().isEmpty) {
          errors['organizationName'] = 'Vui lòng nhập tên tổ chức';
        }
        validatePhone(state.phone, 'phone', errors, required: true);
        validateEmail(state.email, 'email', errors);
        validatePhone(state.secondaryPhone, 'secondaryPhone', errors);
      case PartnerCreateSection.primaryContact:
        if (state.primaryContactEnabled) {
          if (state.primaryContactName.trim().isEmpty) {
            errors['primaryContactName'] =
                'Vui lòng nhập họ và tên người liên hệ';
          }
          validatePhone(
            state.primaryContactPhone,
            'primaryContactPhone',
            errors,
            required: true,
          );
          validatePhone(
            state.primaryContactSecondaryPhone,
            'primaryContactSecondaryPhone',
            errors,
          );
          validateEmail(
            state.primaryContactEmail,
            'primaryContactEmail',
            errors,
          );
        }
      case PartnerCreateSection.invoice:
        final taxDigits = digitsOnly(state.taxCode);
        if (state.taxCode.trim().isNotEmpty &&
            taxDigits.length != 10 &&
            taxDigits.length != 13) {
          errors['taxCode'] = 'MST phải có 10 hoặc 13 chữ số';
        }
        validateEmail(state.invoiceEmail, 'invoiceEmail', errors);
      case PartnerCreateSection.delivery:
      case PartnerCreateSection.note:
        break;
    }
    return errors;
  }

  static void validatePhone(
    String value,
    String key,
    Map<String, String> errors, {
    bool required = false,
  }) {
    final error = VPhoneValidator.validate(value, isRequired: required);
    if (error != null) errors[key] = error;
  }

  static void validateEmail(
    String value,
    String key,
    Map<String, String> errors,
  ) {
    final error = VEmailValidator.validate(value, isRequired: false);
    if (error != null) errors[key] = error;
  }

  static PartnerCreateSection firstErrorSection(
    PartnerCreateState state,
    Map<String, String> errors,
  ) {
    const keysBySection = {
      PartnerCreateSection.role: ['roles'],
      PartnerCreateSection.main: [
        'fullName',
        'organizationName',
        'phone',
        'secondaryPhone',
        'email',
      ],
      PartnerCreateSection.primaryContact: [
        'primaryContactName',
        'primaryContactPhone',
        'primaryContactSecondaryPhone',
        'primaryContactEmail',
      ],
      PartnerCreateSection.invoice: ['taxCode', 'invoiceEmail'],
      PartnerCreateSection.delivery: <String>[],
      PartnerCreateSection.note: <String>[],
    };
    for (final section in state.sections) {
      if (keysBySection[section]!.any(errors.containsKey)) return section;
    }
    return state.activeSection ?? state.sections.first;
  }

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}
