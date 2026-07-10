import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final ScrollController _scrollController = ScrollController();
  late final PartnerListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerListCubit(
      partnerModule: GetIt.instance<IPartnerModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..fetchPartners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchPartners();
    }
  }

  bool get _canCreate => GetIt.instance<IamSession>().hasPermission(PartnerPermissions.create);

  Future<void> _openCreateFlow() async {
    final partnerType = await showPartnerCreateActionSheet(context);
    if (!mounted || partnerType == null) return;

    final createdPartnerId = await context.push<String>(
      '/partner/new',
      extra: partnerType,
    );
    if (!mounted) return;
    if (createdPartnerId != null) {
      await _cubit.fetchPartners(isRefresh: true);
      _showCreatedHandoffSnackBar(createdPartnerId);
    } else {
      await _cubit.fetchPartners(isRefresh: true);
    }
  }

  Future<void> _openFilterSheet(PartnerListState state) async {
    final result = await PartnerFilterBottomSheet.show(
      context,
      role: state.roleFilter,
      partnerType: state.partnerType,
      status: state.status,
    );
    if (result != null) {
      _cubit.applyFilters(
        roleFilter: result['role'] as PartnerRoleFilter?,
        partnerType: result['partnerType'] as PartnerType?,
        status: result['status'] as PartnerStatus?,
        clearRole: result['role'] == null,
        clearType: result['partnerType'] == null,
        clearStatus: result['status'] == null,
      );
    }
  }

  Future<void> _openSortSheet(PartnerListState state) async {
    final result = await PartnerSortBottomSheet.show(
      context,
      initialSort: state.sortOption,
    );
    if (result != null && result != state.sortOption) {
      _cubit.applyFilters(sortOption: result);
    }
  }

  void _showCreatedHandoffSnackBar(String partnerId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã tạo KH & NCC. Chi tiết hồ sơ sẽ có ở bản cập nhật tiếp theo.',
          style: VTypography.bodyDefault.copyWith(color: VColors.neutral0),
        ),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: VColors.neutral0,
          onPressed: () {},
        ),
        backgroundColor: VColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.card)),
        margin: const EdgeInsets.all(VSpacing.space4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final canView = GetIt.instance<IamSession>().hasPermission(PartnerPermissions.view);

    if (!canView) {
      return Scaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        backgroundColor: colors.background,
        appBar: const VAppBar(title: 'KH & NCC', showBackButton: false),
        body: const Center(
          child: Text('Bạn chưa có quyền xem danh sách KH & NCC.'),
        ),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        backgroundColor: colors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              final total = switch (state) {
                PartnerListLoaded(:final total) => total,
                _ => null,
              };
              return VAppBar(
                title: 'KH & NCC',
                titleStyle: VTypography.headingH3.copyWith(
                  color: context.vColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                subtitle: total != null ? '$total đối tác' : null,
                showBackButton: false,
              );
            },
          ),
        ),
        body: Column(
          children: [
            BlocBuilder<PartnerListCubit, PartnerListState>(
              builder: (context, state) {
                final filterCount =
                    (state.partnerType != null ? 1 : 0) +
                    (state.roleFilter != null ? 1 : 0) +
                    (state.status != null ? 1 : 0);
                return PartnerListSearchBar(
                  onSearch: _cubit.searchByKeyword,
                  onFilterTap: () => _openFilterSheet(state),
                  activeFilterCount: filterCount,
                );
              },
            ),
            BlocBuilder<PartnerListCubit, PartnerListState>(
              builder: (context, state) {
                return PartnerListQuickFilters(
                  selectedRole: state.roleFilter,
                  onRoleSelected: (role) {
                    if (role == null) {
                      _cubit.applyFilters(clearRole: true);
                    } else {
                      _cubit.applyFilters(roleFilter: role);
                    }
                  },
                );
              },
            ),
            BlocBuilder<PartnerListCubit, PartnerListState>(
              builder: (context, state) {
                return PartnerActiveFilters(
                  partnerType: state.partnerType,
                  roleFilter: state.roleFilter,
                  status: state.status,
                  onRemoveFilter: _cubit.removeFilter,
                  onClearAll: _cubit.clearFilters,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocBuilder<PartnerListCubit, PartnerListState>(
                    builder: (context, state) {
                      final hasFilter =
                          state.query != null ||
                          state.partnerType != null ||
                          state.roleFilter != null ||
                          state.status != null;
                      final total = switch (state) {
                        PartnerListLoaded(:final total) => total,
                        _ => 0,
                      };
                      return Text(
                        hasFilter ? '$total kết quả phù hợp' : 'Danh sách đối tác',
                        style: VTypography.bodyDefault.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  BlocBuilder<PartnerListCubit, PartnerListState>(
                    builder: (context, state) {
                      return InkWell(
                        onTap: () => _openSortSheet(state),
                        child: Row(
                          children: [
                            Icon(Icons.swap_vert, size: 20, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Sắp xếp',
                              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<PartnerListCubit, PartnerListState>(
                builder: (context, state) {
                  if (state is PartnerListInitial ||
                      (state is PartnerListLoading && state.isFirstLoad)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PartnerListError) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  }

                  final items = switch (state) {
                    PartnerListLoaded(:final items) => items,
                    PartnerListLoading(:final items) => items,
                    _ => <PartnerListItemDto>[],
                  };

                  if (items.isEmpty && state is! PartnerListLoading) {
                    return Center(
                      child: VEmptyState(
                        iconData: Icons.people_outline_rounded,
                        title: 'Chưa có KH & NCC',
                        description: 'Bắt đầu bằng cách thêm hồ sơ cá nhân hoặc tổ chức mới.',
                        actionLabel: _canCreate ? 'Thêm KH & NCC' : null,
                        actionLeadingIcon: _canCreate ? const Icon(Icons.add, size: 18) : null,
                        onActionPressed: _canCreate ? _openCreateFlow : null,
                      ),
                    );
                  }

                  final hasReachedMax = state is PartnerListLoaded && state.hasReachedMax;

                  return RefreshIndicator(
                    onRefresh: () => _cubit.fetchPartners(isRefresh: true),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(VSpacing.space4, 0, VSpacing.space4, 100),
                      itemCount: items.length + (hasReachedMax ? 0 : 1),
                      separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = items[index];
                        return PartnerListItemTile(
                          item: item,
                          onTap: () => context.push('/partner/${item.partnerId}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _canCreate
            ? VFloatingActionButton(
                key: const Key('btn_create_partner'),
                iconData: Icons.add,
                onTap: _openCreateFlow,
                backgroundColor: colors.success,
              )
            : null,
      ),
    );
  }
}
