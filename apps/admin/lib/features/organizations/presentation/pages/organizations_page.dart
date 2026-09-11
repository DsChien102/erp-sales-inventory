import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_tenants_cubit.dart';
import '../bloc/platform_tenants_state.dart';
import 'platform_onboarding_page.dart';
import 'platform_tenant_detail_page.dart';

/// Thin Composition Page — danh sách tổ chức nền tảng (Admin / EP-02 US-08).
class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({
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
        final cubit = PlatformTenantsCubit(
          iamModule: module,
          initialState: PlatformTenantsState(
            status: isUnauthorized
                ? PlatformTenantsStatus.unauthorized
                : hasError
                ? PlatformTenantsStatus.failure
                : PlatformTenantsStatus.initial,
          ),
        );
        if (!hasError && !isUnauthorized) {
          cubit.load();
        }
        return cubit;
      },
      child: _OrganizationsView(iamModule: module),
    );
  }
}

class _OrganizationsView extends StatefulWidget {
  const _OrganizationsView({required this.iamModule});

  final IIamModule iamModule;

  @override
  State<_OrganizationsView> createState() => _OrganizationsViewState();
}

class _OrganizationsViewState extends State<_OrganizationsView> {
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
      context.read<PlatformTenantsCubit>().setSearchQuery(
        _searchController.text,
      );
    });
  }

  void _openFilterBottomSheet() {
    final cubit = context.read<PlatformTenantsCubit>();
    showVBottomSheet(
      context: context,
      child: OrganizationFilterBottomSheet(
        initialCriteria: cubit.state.filterCriteria,
        onApply: cubit.setFilterCriteria,
      ),
    );
  }

  Future<void> _openOnboardingWizard() async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            PlatformOnboardingPage(iamModule: widget.iamModule),
      ),
    );
    if (shouldRefresh == true && mounted) {
      await context.read<PlatformTenantsCubit>().load();
    }
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
    return BlocBuilder<PlatformTenantsCubit, PlatformTenantsState>(
      builder: (context, state) {
        final cubit = context.read<PlatformTenantsCubit>();

        OrganizationEmptyStateType emptyType;
        String? customActionLabel;
        VoidCallback? onEmptyAction;

        if (state.status == PlatformTenantsStatus.unauthorized) {
          emptyType = OrganizationEmptyStateType.unauthorized;
          onEmptyAction = () {
            _searchController.clear();
            cubit.clearFilters();
          };
        } else if (state.status == PlatformTenantsStatus.failure) {
          emptyType = OrganizationEmptyStateType.loadError;
          onEmptyAction = () => cubit.load();
        } else {
          final hasSearchQuery =
              _searchController.text.trim().isNotEmpty ||
              state.searchQuery.trim().isNotEmpty;
          final hasFilter = state.filterCriteria.isFilterActive;
          final isFiltered = hasSearchQuery || hasFilter;

          if (isFiltered) {
            emptyType = OrganizationEmptyStateType.noResults;
            customActionLabel = (hasSearchQuery && !hasFilter)
                ? 'Xóa tìm kiếm'
                : 'Xóa bộ lọc';
            onEmptyAction = () {
              _searchController.clear();
              cubit.clearFilters();
            };
          } else {
            emptyType = OrganizationEmptyStateType.noOrganizations;
            onEmptyAction = () {
              _searchController.clear();
              cubit.clearFilters();
              unawaited(_openOnboardingWizard());
            };
          }
        }

        final filteredItems =
            (state.status == PlatformTenantsStatus.unauthorized ||
                state.status == PlatformTenantsStatus.failure)
            ? const <OrganizationUiModel>[]
            : state.filteredTenants;

        final isLoading =
            state.status == PlatformTenantsStatus.loading &&
            state.tenants.isEmpty;

        return Column(
          children: [
            OrganizationSearchBar(
              controller: _searchController,
              isFilterActive: state.filterCriteria.isFilterActive,
              onFilterTap: _openFilterBottomSheet,
            ),
            OrganizationFilterChips(
              selectedStatus: state.filterCriteria.status,
              onStatusSelected: cubit.setStatusFilter,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OrganizationListContent(
                      organizations: filteredItems,
                      emptyType: emptyType,
                      customActionLabel: customActionLabel,
                      onRefresh: () => cubit.load(),
                      onEmptyAction: onEmptyAction,
                      onItemTap: (organization) async {
                        final shouldRefresh = await Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (context) => PlatformTenantDetailPage(
                                  tenantId: organization.id,
                                  iamModule: widget.iamModule,
                                ),
                              ),
                            );
                        if (shouldRefresh == true && mounted) {
                          await cubit.load();
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
