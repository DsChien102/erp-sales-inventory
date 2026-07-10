import 'package:equatable/equatable.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

enum PartnerFormMode { create, edit }

enum PartnerCreateStatus {
  initial,
  loading,
  submitting,
  duplicate,
  success,
  failure,
  blocked,
}

enum PartnerCreateSection {
  role,
  main,
  primaryContact,
  invoice,
  delivery,
  note,
}

final class PartnerCreateState extends Equatable {
  const PartnerCreateState({
    required this.partnerType,
    this.mode = PartnerFormMode.create,
    this.partnerId,
    this.expectedVersion,
    this.roles = const [],
    this.activeSection = PartnerCreateSection.role,
    this.completedSections = const {},
    this.isDirty = false,
    this.status = PartnerCreateStatus.initial,
    this.errors = const {},
    this.generalError,
    this.duplicateMatches = const [],
    this.duplicateLevel,
    this.createdPartnerId,
    this.personTitle = '',
    this.fullName = '',
    this.nickname = '',
    this.phone = '',
    this.secondaryPhone = '',
    this.email = '',
    this.organizationTypeLabel = '',
    this.organizationName = '',
    this.shortName = '',
    this.internationalName = '',
    this.primaryContactEnabled = false,
    this.primaryContactTitle = '',
    this.primaryContactName = '',
    this.primaryContactPhone = '',
    this.primaryContactSecondaryPhone = '',
    this.primaryContactEmail = '',
    this.taxCode = '',
    this.invoiceName = '',
    this.invoiceAddress = '',
    this.invoiceEmail = '',
    this.deliveryProvince = '',
    this.deliveryCommune = '',
    this.deliveryAddress = '',
    this.note = '',
  });

  final PartnerType partnerType;
  final PartnerFormMode mode;
  final String? partnerId;
  final int? expectedVersion;
  final List<PartnerRoleType> roles;
  final PartnerCreateSection? activeSection;
  final Set<PartnerCreateSection> completedSections;
  final bool isDirty;
  final PartnerCreateStatus status;
  final Map<String, String> errors;
  final String? generalError;
  final List<PartnerDuplicateMatchDto> duplicateMatches;
  final PartnerDuplicateMatchLevel? duplicateLevel;
  final String? createdPartnerId;

  bool get isEditMode => mode == PartnerFormMode.edit;

  final String personTitle;
  final String fullName;
  final String nickname;
  final String phone;
  final String secondaryPhone;
  final String email;

  final String organizationTypeLabel;
  final String organizationName;
  final String shortName;
  final String internationalName;

  final bool primaryContactEnabled;
  final String primaryContactTitle;
  final String primaryContactName;
  final String primaryContactPhone;
  final String primaryContactSecondaryPhone;
  final String primaryContactEmail;

  final String taxCode;
  final String invoiceName;
  final String invoiceAddress;
  final String invoiceEmail;
  final String deliveryProvince;
  final String deliveryCommune;
  final String deliveryAddress;
  final String note;

  bool get isReadOnly => status == PartnerCreateStatus.blocked;
  bool get isSubmitting => status == PartnerCreateStatus.submitting;
  bool get isLoading => status == PartnerCreateStatus.loading;

  bool get canSubmit {
    if (isReadOnly || isLoading || roles.isEmpty) return false;
    // Edit mode: save stays disabled until the user changes something.
    if (isEditMode && !isDirty) return false;
    if (partnerType == PartnerType.person) {
      return fullName.trim().isNotEmpty && phone.trim().isNotEmpty;
    }
    return organizationName.trim().isNotEmpty && phone.trim().isNotEmpty;
  }

  List<PartnerCreateSection> get sections {
    if (partnerType == PartnerType.person) {
      return const [
        PartnerCreateSection.role,
        PartnerCreateSection.main,
        PartnerCreateSection.invoice,
        PartnerCreateSection.delivery,
        PartnerCreateSection.note,
      ];
    }
    if (isEditMode) {
      return const [
        PartnerCreateSection.role,
        PartnerCreateSection.main,
        PartnerCreateSection.invoice,
        PartnerCreateSection.delivery,
        PartnerCreateSection.note,
      ];
    }
    return const [
      PartnerCreateSection.role,
      PartnerCreateSection.main,
      PartnerCreateSection.primaryContact,
      PartnerCreateSection.invoice,
      PartnerCreateSection.delivery,
      PartnerCreateSection.note,
    ];
  }

  PartnerCreateState copyWith({
    PartnerType? partnerType,
    PartnerFormMode? mode,
    String? partnerId,
    int? expectedVersion,
    List<PartnerRoleType>? roles,
    PartnerCreateSection? activeSection,
    bool clearActiveSection = false,
    Set<PartnerCreateSection>? completedSections,
    bool? isDirty,
    PartnerCreateStatus? status,
    Map<String, String>? errors,
    String? generalError,
    bool clearGeneralError = false,
    List<PartnerDuplicateMatchDto>? duplicateMatches,
    PartnerDuplicateMatchLevel? duplicateLevel,
    bool clearDuplicate = false,
    String? createdPartnerId,
    bool clearCreatedPartnerId = false,
    String? personTitle,
    String? fullName,
    String? nickname,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? organizationTypeLabel,
    String? organizationName,
    String? shortName,
    String? internationalName,
    bool? primaryContactEnabled,
    String? primaryContactTitle,
    String? primaryContactName,
    String? primaryContactPhone,
    String? primaryContactSecondaryPhone,
    String? primaryContactEmail,
    String? taxCode,
    String? invoiceName,
    String? invoiceAddress,
    String? invoiceEmail,
    String? deliveryProvince,
    String? deliveryCommune,
    String? deliveryAddress,
    String? note,
  }) {
    return PartnerCreateState(
      partnerType: partnerType ?? this.partnerType,
      mode: mode ?? this.mode,
      partnerId: partnerId ?? this.partnerId,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      roles: roles ?? this.roles,
      activeSection: clearActiveSection
          ? null
          : (activeSection ?? this.activeSection),
      completedSections: completedSections ?? this.completedSections,
      isDirty: isDirty ?? this.isDirty,
      status: status ?? this.status,
      errors: errors ?? this.errors,
      generalError: clearGeneralError ? null : (generalError ?? this.generalError),
      duplicateMatches: clearDuplicate ? const [] : (duplicateMatches ?? this.duplicateMatches),
      duplicateLevel: clearDuplicate ? null : (duplicateLevel ?? this.duplicateLevel),
      createdPartnerId: clearCreatedPartnerId ? null : (createdPartnerId ?? this.createdPartnerId),
      personTitle: personTitle ?? this.personTitle,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      organizationTypeLabel:
          organizationTypeLabel ?? this.organizationTypeLabel,
      organizationName: organizationName ?? this.organizationName,
      shortName: shortName ?? this.shortName,
      internationalName: internationalName ?? this.internationalName,
      primaryContactEnabled: primaryContactEnabled ?? this.primaryContactEnabled,
      primaryContactTitle: primaryContactTitle ?? this.primaryContactTitle,
      primaryContactName: primaryContactName ?? this.primaryContactName,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
      primaryContactSecondaryPhone:
          primaryContactSecondaryPhone ?? this.primaryContactSecondaryPhone,
      primaryContactEmail: primaryContactEmail ?? this.primaryContactEmail,
      taxCode: taxCode ?? this.taxCode,
      invoiceName: invoiceName ?? this.invoiceName,
      invoiceAddress: invoiceAddress ?? this.invoiceAddress,
      invoiceEmail: invoiceEmail ?? this.invoiceEmail,
      deliveryProvince: deliveryProvince ?? this.deliveryProvince,
      deliveryCommune: deliveryCommune ?? this.deliveryCommune,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    partnerType,
    mode,
    partnerId,
    expectedVersion,
    roles,
    activeSection,
    completedSections,
    isDirty,
    status,
    errors,
    generalError,
    duplicateMatches,
    duplicateLevel,
    createdPartnerId,
    personTitle,
    fullName,
    nickname,
    phone,
    secondaryPhone,
    email,
    organizationTypeLabel,
    organizationName,
    shortName,
    internationalName,
    primaryContactEnabled,
    primaryContactTitle,
    primaryContactName,
    primaryContactPhone,
    primaryContactSecondaryPhone,
    primaryContactEmail,
    taxCode,
    invoiceName,
    invoiceAddress,
    invoiceEmail,
    deliveryProvince,
    deliveryCommune,
    deliveryAddress,
    note,
  ];
}

