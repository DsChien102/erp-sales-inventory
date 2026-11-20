import 'package:equatable/equatable.dart';

import 'sales_order_detail_vm.dart';

final class SalesOrderHistoryVm extends Equatable {
  const SalesOrderHistoryVm({
    required this.timeline,
    required this.returns,
  });

  final List<SalesOrderDetailTimelineVm> timeline;
  final List<SalesReturnExchangeSlipItemVm> returns;

  SalesOrderHistoryVm copyWith({
    List<SalesOrderDetailTimelineVm>? timeline,
    List<SalesReturnExchangeSlipItemVm>? returns,
  }) {
    return SalesOrderHistoryVm(
      timeline: timeline ?? this.timeline,
      returns: returns ?? this.returns,
    );
  }

  @override
  List<Object?> get props => [timeline, returns];
}
