import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';

class StockReportState extends Equatable {
  const StockReportState({
    required this.period,
    this.status = ReportStatus.loading,
    this.data,
    this.search = '',
    this.message,
  });

  final ReportPeriod period;
  final ReportStatus status;
  final StockReport? data;
  final String search;
  final String? message;

  StockReportState copyWith({
    ReportPeriod? period,
    ReportStatus? status,
    StockReport? data,
    String? search,
    String? message,
    bool clearMessage = false,
  }) {
    return StockReportState(
      period: period ?? this.period,
      status: status ?? this.status,
      data: data ?? this.data,
      search: search ?? this.search,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [period, status, data, search, message];
}
