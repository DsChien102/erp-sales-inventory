import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_create_form_validator.dart';
import 'partner_create_state.dart';

/// Maps create/edit draft state to application profile inputs.
abstract final class PartnerCreateDraftMapper {
  static PersonProfileInput personProfile(PartnerCreateState state) {
    return PersonProfileInput(
      title: personTitle(state.personTitle),
      fullName: state.fullName.trim(),
      nickname: nullable(state.nickname.trim()),
      phone: normalizePhone(state.phone),
      phone2: nullable(normalizePhone(state.secondaryPhone)),
      email: nullable(state.email.trim()),
      taxCode: nullable(PartnerCreateFormValidator.digitsOnly(state.taxCode)),
      invoice: invoiceProfile(state),
      delivery: deliveryAddress(state),
      note: nullable(state.note.trim()),
    );
  }

  static OrganizationProfileInput organizationProfile(PartnerCreateState state) {
    return OrganizationProfileInput(
      organizationType: resolveOrganizationType(state.organizationTypeLabel),
      organizationName: state.organizationName.trim(),
      shortName: nullable(state.shortName.trim()),
      intlName: nullable(state.internationalName.trim()),
      phone: normalizePhone(state.phone),
      email: nullable(state.email.trim()),
      taxCode: nullable(PartnerCreateFormValidator.digitsOnly(state.taxCode)),
      invoice: invoiceProfile(state),
      delivery: deliveryAddress(state),
      note: nullable(state.note.trim()),
    );
  }

  static PersonProfileInput primaryContactProfile(PartnerCreateState state) {
    return PersonProfileInput(
      title: personTitle(state.primaryContactTitle),
      fullName: state.primaryContactName.trim(),
      phone: normalizePhone(state.primaryContactPhone),
      phone2: nullable(normalizePhone(state.primaryContactSecondaryPhone)),
      email: nullable(state.primaryContactEmail.trim()),
    );
  }

  static InvoiceProfileInput? invoiceProfile(PartnerCreateState state) {
    final name = nullable(state.invoiceName.trim());
    final address = nullable(state.invoiceAddress.trim());
    final email = nullable(state.invoiceEmail.trim());
    if (name == null && address == null && email == null) return null;
    return InvoiceProfileInput(
      invoiceName: name,
      invoiceAddress: address,
      invoiceEmail: email,
    );
  }

  static DeliveryAddressInput? deliveryAddress(PartnerCreateState state) {
    final province = nullable(state.deliveryProvince.trim());
    final commune = nullable(state.deliveryCommune.trim());
    final address = nullable(state.deliveryAddress.trim());
    if (province == null && commune == null && address == null) return null;
    return DeliveryAddressInput(
      province: province,
      commune: commune,
      address: address,
    );
  }

  static String displayName(PartnerCreateState state) =>
      state.partnerType == PartnerType.person
      ? state.fullName.trim()
      : state.organizationName.trim();

  static String organizationTypeLabel(OrganizationType type) {
    return switch (type) {
      OrganizationType.company => 'Công ty/TNHH',
      OrganizationType.businessHousehold => 'Hộ kinh doanh',
      OrganizationType.other => 'Khác',
    };
  }

  static String normalizePhone(String value) {
    final trimmed = value.trim();
    final digits = PartnerCreateFormValidator.digitsOnly(trimmed);
    return trimmed.startsWith('+') && digits.isNotEmpty ? '+$digits' : digits;
  }

  static String? nullable(String value) => value.isEmpty ? null : value;

  static PersonTitle? personTitle(String value) =>
      value.trim().isEmpty ? null : PersonTitle(value.trim());

  static OrganizationType resolveOrganizationType(String value) {
    final normalized = _removeVietnameseTones(value.trim().toLowerCase());
    if (normalized.isEmpty) return OrganizationType.other;

    if (normalized.contains('ho kinh doanh') ||
        normalized.contains('business household') ||
        normalized == 'businesshousehold' ||
        normalized == 'business_household') {
      return OrganizationType.businessHousehold;
    }

    if (normalized.contains('cong ty') ||
        normalized.contains('tnhh') ||
        normalized == 'company') {
      return OrganizationType.company;
    }

    if (normalized == 'khac' || normalized == 'other') {
      return OrganizationType.other;
    }

    return OrganizationType.other;
  }

  static String _removeVietnameseTones(String str) {
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'[đ]'), 'd');
    return str;
  }
}
