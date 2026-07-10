import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

abstract final class PartnerDetailFormatters {
  static String roleBadgeLabel(List<PartnerRoleType> roles) {
    if (roles.length >= 2) return 'KH & NCC';
    if (roles.contains(PartnerRoleType.customer)) return 'KH';
    if (roles.contains(PartnerRoleType.supplier)) return 'NCC';
    return '';
  }

  static String? primaryPhone(PartnerDetailDto detail) {
    return switch (detail.partnerType) {
      PartnerType.person => detail.personProfile?.phone,
      PartnerType.organization => detail.organizationProfile?.phone,
    };
  }

  static String? primaryEmail(PartnerDetailDto detail) {
    return switch (detail.partnerType) {
      PartnerType.person => detail.personProfile?.email,
      PartnerType.organization => detail.organizationProfile?.email,
    };
  }

  static String? taxCode(PartnerDetailDto detail) {
    return switch (detail.partnerType) {
      PartnerType.person => detail.personProfile?.taxCode,
      PartnerType.organization => detail.organizationProfile?.taxCode,
    };
  }

  static InvoiceProfileInput? invoice(PartnerDetailDto detail) {
    return switch (detail.partnerType) {
      PartnerType.person => detail.personProfile?.invoice,
      PartnerType.organization => detail.organizationProfile?.invoice,
    };
  }

  static DeliveryAddressInput? delivery(PartnerDetailDto detail) {
    return switch (detail.partnerType) {
      PartnerType.person => detail.personProfile?.delivery,
      PartnerType.organization => detail.organizationProfile?.delivery,
    };
  }

  static String formatDeliveryAddress(DeliveryAddressInput? delivery) {
    if (delivery == null) return '';
    return [
      delivery.address,
      delivery.commune,
      delivery.province,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
  }

  static String? createdDateLabel(PartnerDetailDto detail) {
    return formatDateTime(detail.createdAt, dateOnly: true);
  }

  static String? formatDateTime(DateTime? value, {bool dateOnly = false}) {
    if (value == null) return null;
    final local = value.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
    if (dateOnly) return date;
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  static String createdActivityText(PartnerDetailDto detail) {
    return 'Tạo mới hồ sơ';
  }
}
