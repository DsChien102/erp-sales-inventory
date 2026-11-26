import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/di/injection.dart';

import '../../data/audit_log_repository.dart';
import 'bloc/tenant_audit_logs_cubit.dart';

/// Shell phân khu Lịch sử quản trị — cung cấp [TenantAuditLogsCubit] dùng chung giữa danh sách và chi tiết.
class AuditAreaShell extends StatelessWidget {
  const AuditAreaShell({
    super.key,
    required this.child,
    this.auditLogs,
    this.clockLocal,
    this.cubit,
  });

  final Widget child;
  final AuditLogRepository? auditLogs;
  final DateTime Function()? clockLocal;
  final TenantAuditLogsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: child,
      );
    }
    return BlocProvider(
      create: (_) => TenantAuditLogsCubit(
        auditLogs: auditLogs ?? getIt<AuditLogRepository>(),
        clockLocal: clockLocal,
      )..search(),
      child: child,
    );
  }
}
