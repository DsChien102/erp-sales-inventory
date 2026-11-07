import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/features/sales/presentation/models/return_exchange_order/sales_return_exchange_detail_vm.dart';

enum SalesReturnExchangeDetailStatus {
  initial,
  loading,
  loaded,
  projectionPending,
  notFound,
  blocked,
  retryableFailure,
  failure,
}

class SalesReturnExchangeDetailState extends Equatable {
  const SalesReturnExchangeDetailState({
    required this.orderId,
    required this.returnExchangeId,
    this.detail,
    this.orderDetail,
    this.returnSummary,
    this.screenError,
    this.status = SalesReturnExchangeDetailStatus.initial,
  });

  final String orderId;
  final String returnExchangeId;
  final SalesReturnExchangeDetailVm? detail;
  final SalesOrderDetailDto? orderDetail;
  final SalesOrderReturnSummaryDto? returnSummary;
  final String? screenError;
  final SalesReturnExchangeDetailStatus status;

  String get orderNumber {
    final num = orderDetail?.order.orderNumber;
    return (num != null && num.isNotEmpty) ? num : (detail?.referenceNumber ?? '');
  }

  String get customerDisplayName {
    final name = orderDetail?.customer?.displayName;
    return (name != null && name.isNotEmpty) ? name : '';
  }

  String get customerPhone {
    final phone = orderDetail?.customer?.phoneNumber;
    return (phone != null && phone.isNotEmpty) ? phone : '';
  }

  String get storeDisplayName {
    final name = orderDetail?.store.displayName;
    return (name != null && name.isNotEmpty) ? name : '';
  }

  String get storeCode {
    final code = orderDetail?.store.storeCode;
    return (code != null && code.isNotEmpty) ? code : '';
  }

  SalesReturnExchangeDetailState copyWith({
    SalesReturnExchangeDetailVm? detail,
    SalesOrderDetailDto? orderDetail,
    SalesOrderReturnSummaryDto? returnSummary,
    String? screenError,
    SalesReturnExchangeDetailStatus? status,
    bool clearDetail = false,
    bool clearScreenError = false,
  }) {
    return SalesReturnExchangeDetailState(
      orderId: orderId,
      returnExchangeId: returnExchangeId,
      detail: clearDetail ? null : (detail ?? this.detail),
      orderDetail: orderDetail ?? this.orderDetail,
      returnSummary: returnSummary ?? this.returnSummary,
      screenError: clearScreenError ? null : (screenError ?? this.screenError),
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    returnExchangeId,
    detail,
    orderDetail,
    returnSummary,
    screenError,
    status,
  ];
}
