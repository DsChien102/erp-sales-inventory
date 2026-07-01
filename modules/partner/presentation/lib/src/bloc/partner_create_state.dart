enum PartnerCreateStatus { initial, loading, duplicateWarning, success, error }

class PartnerCreateState {
  final PartnerCreateStatus status;
  final String role; // 'customer', 'supplier', 'both'
  final String profileType; // 'individual', 'company', 'household'
  final String name;
  final String phone;
  final String email;
  final String address;
  final String taxId;
  final String billingName;
  final String billingAddress;
  final String billingEmail;
  final String contactName;
  final String note;
  
  final String? errorMessage;
  final List<String> duplicateWarnings;
  final bool showValidationErrors;

  const PartnerCreateState({
    this.status = PartnerCreateStatus.initial,
    this.role = 'customer',
    this.profileType = 'individual',
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxId = '',
    this.billingName = '',
    this.billingAddress = '',
    this.billingEmail = '',
    this.contactName = '',
    this.note = '',
    this.errorMessage,
    this.duplicateWarnings = const [],
    this.showValidationErrors = false,
  });

  bool get isDirty {
    return name.isNotEmpty ||
        phone.isNotEmpty ||
        email.isNotEmpty ||
        address.isNotEmpty ||
        taxId.isNotEmpty ||
        contactName.isNotEmpty ||
        note.isNotEmpty;
  }

  PartnerCreateState copyWith({
    PartnerCreateStatus? status,
    String? role,
    String? profileType,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? billingName,
    String? billingAddress,
    String? billingEmail,
    String? contactName,
    String? note,
    String? errorMessage,
    List<String>? duplicateWarnings,
    bool? showValidationErrors,
  }) {
    return PartnerCreateState(
      status: status ?? this.status,
      role: role ?? this.role,
      profileType: profileType ?? this.profileType,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      billingName: billingName ?? this.billingName,
      billingAddress: billingAddress ?? this.billingAddress,
      billingEmail: billingEmail ?? this.billingEmail,
      contactName: contactName ?? this.contactName,
      note: note ?? this.note,
      errorMessage: errorMessage,
      duplicateWarnings: duplicateWarnings ?? this.duplicateWarnings,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
    );
  }
}
