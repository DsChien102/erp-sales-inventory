import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

enum SalesReturnExchangeSessionStatus {
  initial,
  loading,
  ready,
  blocked,
  saving,
  stale,
  retryableFailure,
  failure,
  discarded,
}

final class SalesReturnLineEdit extends Equatable {
  const SalesReturnLineEdit({
    required this.salesOrderLineId,
    required this.quantityMicros,
  });

  final String salesOrderLineId;
  final int quantityMicros;

  SalesReturnLineEdit copyWith({
    int? quantityMicros,
  }) {
    return SalesReturnLineEdit(
      salesOrderLineId: salesOrderLineId,
      quantityMicros: quantityMicros ?? this.quantityMicros,
    );
  }

  @override
  List<Object?> get props => [
    salesOrderLineId,
    quantityMicros,
  ];
}

final class SalesExchangeLineEdit extends Equatable {
  const SalesExchangeLineEdit({
    required this.productId,
    required this.productUnitId,
    required this.productName,
    required this.sku,
    required this.unitLabel,
    required this.unitPrice,
    required this.quantityMicros,
  });

  final String productId;
  final String productUnitId;
  final String productName;
  final String? sku;
  final String unitLabel;
  final MoneyDto unitPrice;
  final int quantityMicros;

  SalesExchangeLineEdit copyWith({int? quantityMicros, MoneyDto? unitPrice}) {
    return SalesExchangeLineEdit(
      productId: productId,
      productUnitId: productUnitId,
      productName: productName,
      sku: sku,
      unitLabel: unitLabel,
      unitPrice: unitPrice ?? this.unitPrice,
      quantityMicros: quantityMicros ?? this.quantityMicros,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productUnitId,
    productName,
    sku,
    unitLabel,
    unitPrice,
    quantityMicros,
  ];
}

class SalesReturnExchangeSessionState extends Equatable {
  const SalesReturnExchangeSessionState({
    required this.orderId,
    this.orderNumber = '',
    this.customerDisplayName = '',
    this.sourceOrderVersion,
    this.returnExchangeId,
    this.draftVersion,
    this.returnableLines = const <ReturnableOrderLineDto>[],
    this.returnEdits = const <SalesReturnLineEdit>[],
    this.exchangeEdits = const <SalesExchangeLineEdit>[],
    this.blockers = const <SalesBlockerDto>[],
    this.fieldError,
    this.screenError,
    this.status = SalesReturnExchangeSessionStatus.initial,
    this.entrySource = ReturnExchangeEntrySource.standard,
  });

  final String orderId;
  final String orderNumber;
  final String customerDisplayName;
  final int? sourceOrderVersion;
  final String? returnExchangeId;
  final int? draftVersion;
  final List<ReturnableOrderLineDto> returnableLines;
  final List<SalesReturnLineEdit> returnEdits;
  final List<SalesExchangeLineEdit> exchangeEdits;
  final List<SalesBlockerDto> blockers;
  final String? fieldError;
  final String? screenError;
  final SalesReturnExchangeSessionStatus status;
  final ReturnExchangeEntrySource entrySource;

  bool get canProceed {
    if (status != SalesReturnExchangeSessionStatus.ready &&
        status != SalesReturnExchangeSessionStatus.retryableFailure &&
        status != SalesReturnExchangeSessionStatus.stale) {
      return false;
    }
    return returnEdits.any((edit) => edit.quantityMicros > 0);
  }

  SalesReturnExchangeSessionState copyWith({
    String? orderNumber,
    String? customerDisplayName,
    int? sourceOrderVersion,
    String? returnExchangeId,
    int? draftVersion,
    List<ReturnableOrderLineDto>? returnableLines,
    List<SalesReturnLineEdit>? returnEdits,
    List<SalesExchangeLineEdit>? exchangeEdits,
    List<SalesBlockerDto>? blockers,
    String? fieldError,
    String? screenError,
    SalesReturnExchangeSessionStatus? status,
    ReturnExchangeEntrySource? entrySource,
    bool clearReturnExchangeId = false,
    bool clearDraftVersion = false,
    bool clearFieldError = false,
    bool clearScreenError = false,
  }) {
    return SalesReturnExchangeSessionState(
      orderId: orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerDisplayName: customerDisplayName ?? this.customerDisplayName,
      sourceOrderVersion: sourceOrderVersion ?? this.sourceOrderVersion,
      returnExchangeId: clearReturnExchangeId ? null : (returnExchangeId ?? this.returnExchangeId),
      draftVersion: clearDraftVersion ? null : (draftVersion ?? this.draftVersion),
      returnableLines: returnableLines ?? this.returnableLines,
      returnEdits: returnEdits ?? this.returnEdits,
      exchangeEdits: exchangeEdits ?? this.exchangeEdits,
      blockers: blockers ?? this.blockers,
      fieldError: clearFieldError ? null : (fieldError ?? this.fieldError),
      screenError: clearScreenError ? null : (screenError ?? this.screenError),
      status: status ?? this.status,
      entrySource: entrySource ?? this.entrySource,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    orderNumber,
    customerDisplayName,
    sourceOrderVersion,
    returnExchangeId,
    draftVersion,
    returnableLines,
    returnEdits,
    exchangeEdits,
    blockers,
    fieldError,
    screenError,
    status,
    entrySource,
  ];
}
