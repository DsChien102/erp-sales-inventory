import 'package:erp/core/di/injection.dart';
import 'package:erp/core/iam/iam_load_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/platform_tenant_repository.dart';
import '../platform_navigation.dart';
import '../../logic/platform_tenants_cubit.dart';
import '../../logic/platform_tenants_state.dart';
import '../widgets/platform_organization_empty_view.dart';
import '../widgets/platform_organization_filter_chips.dart';
import '../widgets/platform_organization_list_content.dart';
import '../widgets/platform_organization_search_bar.dart';

/// C1 — `/more/platform/organizations`: danh sách tổ chức của Platform Admin.
class PlatformOrganizationsPage extends StatelessWidget {
  const PlatformOrganizationsPage({super.key, this.repository, this.cubit});

  final PlatformTenantRepository? repository;

  /// Cho test: dùng cubit dựng sẵn thay vì tạo từ [repository].
  final PlatformTenantsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(value: provided, child: const _View());
    }
    return BlocProvider(
      create: (_) => PlatformTenantsCubit(
        tenants: repository ?? getIt<PlatformTenantRepository>(),
      )..load(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, String tenantId) async {
    final cubit = context.read<PlatformTenantsCubit>();
    await context.push('/more/platform/organizations/$tenantId');
    // Trạng thái có thể đã đổi (tạm ngừng / đóng) ở trang chi tiết.
    if (mounted) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<PlatformTenantsCubit>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Tổ chức',
        subtitle: 'Quản trị nền tảng',
        showBackButton: true,
        leading: IconButton(
          icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
          onPressed: () => leavePlatformPage(context),
        ),
      ),
      body: BlocBuilder<PlatformTenantsCubit, PlatformTenantsState>(
        builder: (context, state) {
          return Column(
            children: [
              PlatformOrganizationSearchBar(
                controller: _search,
                onChanged: cubit.setQuery,
              ),
              PlatformOrganizationFilterChips(
                selected: state.filter,
                onSelected: cubit.setFilter,
              ),
              Expanded(child: _body(context, state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, PlatformTenantsState state, PlatformTenantsCubit cubit) {
    switch (state.status) {
      case IamLoadStatus.initial:
      case IamLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case IamLoadStatus.unauthorized:
        return const PlatformOrganizationEmptyView(
          type: PlatformOrganizationEmptyType.unauthorized,
        );
      case IamLoadStatus.failure:
        return PlatformOrganizationEmptyView(
          type: PlatformOrganizationEmptyType.loadError,
          onAction: cubit.load,
        );
      case IamLoadStatus.empty:
        if (state.isFiltered) {
          return PlatformOrganizationEmptyView(
            type: PlatformOrganizationEmptyType.noResults,
            actionLabel: state.filter == PlatformTenantFilter.all ? 'Xóa tìm kiếm' : 'Xóa bộ lọc',
            onAction: () {
              _search.clear();
              cubit.clearFilters();
            },
          );
        }
        return const PlatformOrganizationEmptyView(
          type: PlatformOrganizationEmptyType.noOrganizations,
        );
      case IamLoadStatus.success:
        return PlatformOrganizationListContent(
          tenants: state.items,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.load,
          onTap: (tenant) => _open(context, tenant.tenantId),
        );
    }
  }
}
