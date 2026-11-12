import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';

class SupplierPurchaseState extends Equatable {
  const SupplierPurchaseState({
    required this.period,
    this.status = ReportStatus.loading,
    this.data,
    this.message,
  });

  final ReportPeriod period;
  final ReportStatus status;
  final SupplierPurchaseReport? data;
  final String? message;

  SupplierPurchaseState copyWith({
    ReportPeriod? period,
    ReportStatus? status,
    SupplierPurchaseReport? data,
    String? message,
    bool clearMessage = false,
  }) {
    return SupplierPurchaseState(
      period: period ?? this.period,
      status: status ?? this.status,
      data: data ?? this.data,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [period, status, data, message];
}
