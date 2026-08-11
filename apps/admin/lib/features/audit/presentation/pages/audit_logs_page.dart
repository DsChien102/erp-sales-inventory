import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_audit_logs_cubit.dart';
import '../bloc/platform_audit_logs_state.dart';

/// Thin Composition Page — nhật ký nền tảng (Admin / EP-02 US-10).
class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({
    super.key,
    this.iamModule,
    this.hasError = false,
    this.isUnauthorized = false,
  });

  final IIamModule? iamModule;
  final bool hasError;
  final bool isUnauthorized;

  @override
  Widget build(BuildContext context) {
    final module = iamModule ?? getIt<IIamModule>();
    return BlocProvider(
      create: (_) {
        final cubit = PlatformAuditLogsCubit(
          iamModule: module,
          initialState: PlatformAuditLogsState(
            status: isUnauthorized
                ? PlatformAuditLogsStatus.unauthorized
                : hasError
                ? PlatformAuditLogsStatus.failure
                : PlatformAuditLogsStatus.initial,
          ),
        );
        if (!hasError && !isUnauthorized) {
          cubit.load();
        }
        return cubit;
      },
      child: const _AuditLogsView(),
    );
  }
}

class _AuditLogsView extends StatefulWidget {
  const _AuditLogsView();

  @override
  State<_AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<_AuditLogsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<PlatformAuditLogsCubit>().setSearchQuery(
        _searchController.text,
      );
    });
  }

  void _openFilterBottomSheet() {
    final cubit = context.read<PlatformAuditLogsCubit>();
    showVBottomSheet(
      context: context,
      child: AuditLogFilterBottomSheet(
        initialCriteria: cubit.state.filterCriteria,
        onApply: cubit.setFilterCriteria,
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformAuditLogsCubit, PlatformAuditLogsState>(
      builder: (context, state) {
        if (state.status == PlatformAuditLogsStatus.unauthorized) {
          return const Center(child: Text('Không có quyền xem nhật ký'));
        }
        if (state.status == PlatformAuditLogsStatus.failure) {
          return Center(
            child: Text(state.errorMessage ?? 'Không tải được nhật ký'),
          );
        }

        final filteredLogs = state.filteredLogs;
        final cubit = context.read<PlatformAuditLogsCubit>();
        final isLoading =
            state.status == PlatformAuditLogsStatus.loading &&
            state.logs.isEmpty;

        return Column(
          children: [
            OrganizationSearchBar(
              controller: _searchController,
              isFilterActive: state.filterCriteria.isFilterActive,
              onFilterTap: _openFilterBottomSheet,
            ),
            AuditLogFilterChips(
              selectedStatus: state.filterCriteria.status,
              onStatusSelected: (status) {
                cubit.setFilterCriteria(
                  state.filterCriteria.copyWith(
                    status: status,
                    clearStatus: status == null,
                  ),
                );
              },
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AuditLogListContent(
                      logs: filteredLogs,
                      onRefresh: () => cubit.load(),
                      onItemTap: (log) async {
                        final detail = await cubit.loadDetail(log.id);
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AuditLogDetailBody(
                              log: detail ?? log,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
