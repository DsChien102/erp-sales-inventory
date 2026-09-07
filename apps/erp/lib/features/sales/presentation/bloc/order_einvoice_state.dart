import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

enum OrderEInvoiceStatus { idle, submitting, previewing, downloading, error }

class OrderEInvoiceState extends Equatable {
  const OrderEInvoiceState({
    required this.salesOrderId,
    required this.orderVersion,
    required this.projection,
    this.readiness,
    this.isBuyerNotReady = false,
    this.status = OrderEInvoiceStatus.idle,
    this.errorMessage,
    this.failureCode,
    this.lastFailureMessage,
    this.previewViewerUrl,
    this.officialViewerUrl,
    this.templateNumber,
    this.templateSymbol,
    this.authorityMode,
    this.isPageActive = true,
  });

  final String salesOrderId;
  final int orderVersion;
  final OrderInvoiceProjectionDto projection;
  final IssuanceReadinessDto? readiness;
  final bool isBuyerNotReady;
  final OrderEInvoiceStatus status;
  final String? errorMessage;
  final String? failureCode;
  final String? lastFailureMessage;
  final String? previewViewerUrl;
  final String? officialViewerUrl;
  final String? templateNumber;
  final String? templateSymbol;
  final String? authorityMode;
  final bool isPageActive;

  bool get isTerminal =>
      projection.issuanceDisplayState == IssuanceDisplayState.issued;

  OrderEInvoiceState toProcessing() {
    return copyWith(
      status: OrderEInvoiceStatus.idle,
      projection: OrderInvoiceProjectionDto(
        salesOrderId: salesOrderId,
        issuanceDisplayState: IssuanceDisplayState.processing,
        deliveryDisplayState: projection.deliveryDisplayState,
        actions: const [],
      ),
      clearError: true,
    );
  }

  OrderEInvoiceState copyWith({
    String? salesOrderId,
    int? orderVersion,
    OrderInvoiceProjectionDto? projection,
    IssuanceReadinessDto? readiness,
    bool? isBuyerNotReady,
    OrderEInvoiceStatus? status,
    String? errorMessage,
    String? failureCode,
    String? lastFailureMessage,
    String? previewViewerUrl,
    String? officialViewerUrl,
    String? templateNumber,
    String? templateSymbol,
    String? authorityMode,
    bool? isPageActive,
    bool clearError = false,
    bool clearPreviewUrl = false,
  }) {
    return OrderEInvoiceState(
      salesOrderId: salesOrderId ?? this.salesOrderId,
      orderVersion: orderVersion ?? this.orderVersion,
      projection: projection ?? this.projection,
      readiness: readiness ?? this.readiness,
      isBuyerNotReady: isBuyerNotReady ?? this.isBuyerNotReady,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failureCode: clearError ? null : (failureCode ?? this.failureCode),
      lastFailureMessage:
          clearError ? null : (lastFailureMessage ?? this.lastFailureMessage),
      previewViewerUrl:
          clearPreviewUrl ? null : (previewViewerUrl ?? this.previewViewerUrl),
      officialViewerUrl: officialViewerUrl ?? this.officialViewerUrl,
      templateNumber: templateNumber ?? this.templateNumber,
      templateSymbol: templateSymbol ?? this.templateSymbol,
      authorityMode: authorityMode ?? this.authorityMode,
      isPageActive: isPageActive ?? this.isPageActive,
    );
  }

  @override
  List<Object?> get props => [
    salesOrderId,
    orderVersion,
    projection,
    readiness,
    isBuyerNotReady,
    status,
    errorMessage,
    failureCode,
    lastFailureMessage,
    previewViewerUrl,
    officialViewerUrl,
    templateNumber,
    templateSymbol,
    authorityMode,
    isPageActive,
  ];
}
