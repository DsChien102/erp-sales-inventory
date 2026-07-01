import 'package:vet45_partner_application/application.dart';

enum PartnerEditStatus { initial, loadingData, loadingDataError, ready, saving, duplicateWarning, success, error }

class PartnerEditState {
  final PartnerEditStatus status;
  final String partnerId;
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
  final String note;

  final int expectedVersion;
  final String createdBy;
  final DateTime? createdAt;
  final String statusKey;
  
  final String? errorMessage;
  final List<PartnerDuplicateMatchDto> duplicateWarnings;
  
  // Track if any changes were made
  final bool hasChanges;

  const PartnerEditState({
    this.status = PartnerEditStatus.initial,
    this.partnerId = '',
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
    this.note = '',
    this.expectedVersion = 1,
    this.createdBy = '',
    this.createdAt,
    this.statusKey = 'active',
    this.errorMessage,
    this.duplicateWarnings = const [],
    this.hasChanges = false,
  });

  PartnerEditState copyWith({
    PartnerEditStatus? status,
    String? partnerId,
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
    String? note,
    int? expectedVersion,
    String? createdBy,
    DateTime? createdAt,
    String? statusKey,
    String? errorMessage,
    List<PartnerDuplicateMatchDto>? duplicateWarnings,
    bool? hasChanges,
  }) {
    return PartnerEditState(
      status: status ?? this.status,
      partnerId: partnerId ?? this.partnerId,
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
      note: note ?? this.note,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      statusKey: statusKey ?? this.statusKey,
      errorMessage: errorMessage,
      duplicateWarnings: duplicateWarnings ?? this.duplicateWarnings,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}
