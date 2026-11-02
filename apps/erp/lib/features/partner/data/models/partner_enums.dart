/// Root partner classification — person or organization profile.
///
/// Thứ tự giá trị giữ nguyên: `index` được dùng khi sắp xếp.
enum PartnerType {
  person,
  organization,
}

/// Partner lifecycle status.
enum PartnerStatus {
  active,
  inactive,
  deleted,
}

/// Transaction role assigned to a partner.
///
/// Thứ tự giá trị giữ nguyên: `PartnerCreateCubit.toggleRole` sắp `roles` theo `index`.
enum PartnerRoleType {
  customer,
  supplier,
}

/// Organization sub-type for organization partners.
enum OrganizationType {
  company,
  businessHousehold,
  other,
}

/// Actions the current principal may perform on a partner detail screen.
enum PartnerAvailableAction {
  update,
  deactivate,
  reactivate,
  delete,
  transform,
  manageContacts,
  viewHistory,
}

/// Duplicate match field for warning flows.
enum PartnerDuplicateMatchField {
  phone,
  email,
  taxCode,
  name,
}

/// Confidence level used by the create flow to choose the duplicate UI.
enum PartnerDuplicateMatchLevel {
  possible,
  exact,
}
