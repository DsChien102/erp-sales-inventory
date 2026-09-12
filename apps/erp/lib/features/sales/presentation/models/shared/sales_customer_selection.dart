import 'package:equatable/equatable.dart';

/// Kết quả chọn khách hàng từ SG-04 → SG-02.
final class SalesCustomerSelection extends Equatable {
  const SalesCustomerSelection({
    required this.isWalkIn,
    required this.displayName,
    this.partnerId,
    this.phone,
    this.isOrganization = false,
    this.taxCode,
  });

  final bool isWalkIn;
  final String displayName;
  final String? partnerId;
  final String? phone;
  final bool isOrganization;
  final String? taxCode;

  factory SalesCustomerSelection.walkIn() => const SalesCustomerSelection(
    isWalkIn: true,
    displayName: 'Khách lẻ',
    isOrganization: false,
  );

  @override
  List<Object?> get props => [
    isWalkIn,
    displayName,
    partnerId,
    phone,
    isOrganization,
    taxCode,
  ];
}

final class SalesCustomerListItemVm extends Equatable {
  const SalesCustomerListItemVm({
    required this.partnerId,
    required this.displayName,
    this.phone,
    this.subtitle,
    this.isBlocked = false,
    this.isOrganization = false,
    this.taxCode,
  });

  final String partnerId;
  final String displayName;
  final String? phone;
  final String? subtitle;
  final bool isBlocked;
  final bool isOrganization;
  final String? taxCode;

  SalesCustomerSelection toSelection() => SalesCustomerSelection(
    isWalkIn: false,
    displayName: displayName,
    partnerId: partnerId,
    phone: phone,
    isOrganization: isOrganization,
    taxCode: taxCode,
  );

  @override
  List<Object?> get props => [
    partnerId,
    displayName,
    phone,
    subtitle,
    isBlocked,
    isOrganization,
    taxCode,
  ];
}
