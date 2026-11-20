import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';

class MovementDetailState extends Equatable {
  const MovementDetailState({
    this.status = ReportStatus.loading,
    this.data,
    this.message,
  });

  final ReportStatus status;
  final MovementDetail? data;
  final String? message;

  @override
  List<Object?> get props => [status, data, message];
}
