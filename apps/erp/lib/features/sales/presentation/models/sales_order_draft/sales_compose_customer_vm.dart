import 'package:equatable/equatable.dart';
import '../shared/sales_customer_selection.dart';

final class SalesComposeCustomerVm extends Equatable {
  const SalesComposeCustomerVm({
    required this.displayName,
    this.phone,
    this.partnerId,
    this.isWalkIn = false,
    this.isOrganization = false,
    this.taxCode,
  });

  final String displayName;
  final String? phone;
  final String? partnerId;
  final bool isWalkIn;
  final bool isOrganization;
  final String? taxCode;

  bool get isOrganizationWithoutTaxCode =>
      !isWalkIn && isOrganization && (taxCode == null || taxCode!.trim().isEmpty);

  factory SalesComposeCustomerVm.walkIn() => const SalesComposeCustomerVm(
    displayName: 'Khách lẻ',
    isWalkIn: true,
    isOrganization: false,
  );

  factory SalesComposeCustomerVm.fromSelection(SalesCustomerSelection selection) {
    if (selection.isWalkIn) return SalesComposeCustomerVm.walkIn();
    return SalesComposeCustomerVm(
      displayName: selection.displayName,
      phone: selection.phone,
      partnerId: selection.partnerId,
      isWalkIn: false,
      isOrganization: selection.isOrganization,
      taxCode: selection.taxCode,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    phone,
    partnerId,
    isWalkIn,
    isOrganization,
    taxCode,
  ];
}
