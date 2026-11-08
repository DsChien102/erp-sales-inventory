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
    this.hasLoadedProjection = true,
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
    this.downloadingDocumentType,
    this.isOpeningOfficialView = false,
  });

  final String salesOrderId;
  final int orderVersion;
  final OrderInvoiceProjectionDto projection;
  final IssuanceReadinessDto? readiness;
  final bool isBuyerNotReady;

  /// False until the first authoritative refresh snapshot is applied.
  final bool hasLoadedProjection;
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
  final InvoiceDocumentType? downloadingDocumentType;

  /// True only while S4a official-view request/poll is in flight.
  final bool isOpeningOfficialView;

  bool get isDownloadingDocument => downloadingDocumentType != null;

  bool isDownloading(InvoiceDocumentType type) => downloadingDocumentType == type;

  bool get isTerminal {
    final issuance = projection.issuanceDisplayState;
    return issuance == IssuanceDisplayState.issued || issuance == IssuanceDisplayState.failed;
  }

  bool get shouldPoll =>
      !hasLoadedProjection ||
      !isTerminal ||
      projection.deliveryPending ||
      projection.deliveryDisplayState == DeliveryDisplayState.sending;

  bool get canInteract {
    if (!hasLoadedProjection) return false;
    return switch (projection.issuanceDisplayState) {
      IssuanceDisplayState.notIssued => readiness != null,
      IssuanceDisplayState.processing => false,
      IssuanceDisplayState.issued || IssuanceDisplayState.failed => true,
    };
  }

  OrderEInvoiceState toProcessing() {
    return copyWith(
      status: OrderEInvoiceStatus.idle,
      hasLoadedProjection: true,
      projection: OrderInvoiceProjectionDto(
        salesOrderId: salesOrderId,
        issuanceDisplayState: IssuanceDisplayState.processing,
        deliveryDisplayState: projection.deliveryDisplayState,
        actions: const [],
      ),
      isOpeningOfficialView: false,
      clearError: true,
      clearFailure: true,
      clearDownloadingDocumentType: true,
    );
  }

  OrderEInvoiceState copyWith({
    String? salesOrderId,
    int? orderVersion,
    OrderInvoiceProjectionDto? projection,
    IssuanceReadinessDto? readiness,
    bool? isBuyerNotReady,
    bool? hasLoadedProjection,
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
    InvoiceDocumentType? downloadingDocumentType,
    bool? isOpeningOfficialView,
    bool clearError = false,
    bool clearFailure = false,
    bool clearPreviewUrl = false,
    bool clearOfficialViewerUrl = false,
    bool clearDownloadingDocumentType = false,
  }) {
    return OrderEInvoiceState(
      salesOrderId: salesOrderId ?? this.salesOrderId,
      orderVersion: orderVersion ?? this.orderVersion,
      projection: projection ?? this.projection,
      readiness: readiness ?? this.readiness,
      isBuyerNotReady: isBuyerNotReady ?? this.isBuyerNotReady,
      hasLoadedProjection: hasLoadedProjection ?? this.hasLoadedProjection,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failureCode: clearFailure ? null : (failureCode ?? this.failureCode),
      lastFailureMessage: clearFailure ? null : (lastFailureMessage ?? this.lastFailureMessage),
      previewViewerUrl: clearPreviewUrl ? null : (previewViewerUrl ?? this.previewViewerUrl),
      officialViewerUrl: clearOfficialViewerUrl
          ? null
          : (officialViewerUrl ?? this.officialViewerUrl),
      templateNumber: templateNumber ?? this.templateNumber,
      templateSymbol: templateSymbol ?? this.templateSymbol,
      authorityMode: authorityMode ?? this.authorityMode,
      isPageActive: isPageActive ?? this.isPageActive,
      downloadingDocumentType: clearDownloadingDocumentType
          ? null
          : (downloadingDocumentType ?? this.downloadingDocumentType),
      isOpeningOfficialView: isOpeningOfficialView ?? this.isOpeningOfficialView,
    );
  }

  @override
  List<Object?> get props => [
    salesOrderId,
    orderVersion,
    projection,
    readiness,
    isBuyerNotReady,
    hasLoadedProjection,
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
    downloadingDocumentType,
    isOpeningOfficialView,
  ];
}
