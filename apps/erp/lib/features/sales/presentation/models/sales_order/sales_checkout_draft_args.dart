import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

final class SalesCheckoutDraftArgs extends Equatable {
  SalesCheckoutDraftArgs({
    required this.runtimeDraftId,
    required this.customerDisplayName,
    required this.isWalkIn,
    required this.currencyCode,
    required this.provisionalTotalAmountMinor,
    required List<CheckoutLineInput> lines,
    required this.commercialSnapshot,
    this.sourceDraftId,
    this.customerId,
    this.customerPhone,
    this.orderNote,
    this.expectedSourceVersion,
  }) : lines = List<CheckoutLineInput>.unmodifiable(lines);

  final String runtimeDraftId;
  final String? sourceDraftId;
  final String? customerId;
  final String customerDisplayName;
  final String? customerPhone;
  final bool isWalkIn;
  final String currencyCode;
  final String? orderNote;
  final int? expectedSourceVersion;
  final int provisionalTotalAmountMinor;
  final List<CheckoutLineInput> lines;
  final SalesCommercialSnapshotInput commercialSnapshot;

  @override
  List<Object?> get props => [
    runtimeDraftId,
    sourceDraftId,
    customerId,
    customerDisplayName,
    customerPhone,
    isWalkIn,
    currencyCode,
    orderNote,
    expectedSourceVersion,
    provisionalTotalAmountMinor,
    lines,
    commercialSnapshot,
  ];
}
