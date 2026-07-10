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
  int? _lastTotal;

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

    // Always refresh when returning from create (success or cancel).
    await _cubit.fetchPartners(isRefresh: true);
    if (!mounted) return;

    if (createdPartnerId != null) {
      _showCreatedHandoffSnackBar(createdPartnerId);
      await context.push('/partner/$createdPartnerId?created=1');
      if (mounted) {
        await _cubit.fetchPartners(isRefresh: true);
      }
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
          child: _CustomEmptyState(
            iconData: Icons.lock_outline_rounded,
            title: 'Bạn không có quyền xem\nKH & NCC',
            description: 'Liên hệ quản trị viên để được cấp quyền.',
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('wgt_e01_u02_fr01_02'),
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: BlocBuilder<PartnerListCubit, PartnerListState>(
            builder: (context, state) {
              if (state is PartnerListLoaded) {
                _lastTotal = state.total;
              }
              final total = state is PartnerListLoaded ? state.total : (_lastTotal ?? 0);
              return VAppBar(
                title: 'KH & NCC',
                titleStyle: VTypography.headingH3.copyWith(
                  color: context.vColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                subtitle: '$total đối tác',
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
                    return Center(
                      child: _CustomEmptyState(
                        iconData: Icons.cloud_off_rounded,
                        iconColor: colors.danger,
                        title: 'Không tải được danh sách',
                        description: 'Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.',
                        actionLabel: 'Thử lại',
                        onActionPressed: () => _cubit.fetchPartners(isRefresh: true),
                        buttonColor: colors.success,
                      ),
                    );
                  }

                  final items = switch (state) {
                    PartnerListLoaded(:final items) => items,
                    PartnerListLoading(:final items) => items,
                    _ => <PartnerListItemDto>[],
                  };

                  if (items.isEmpty && state is! PartnerListLoading) {
                    final hasQuery = state.query != null && state.query!.isNotEmpty;
                    if (hasQuery) {
                      return Center(
                        child: _CustomEmptyState(
                          iconData: Icons.search_rounded,
                          title: 'Không tìm thấy kết quả',
                          description: 'Thử kiểm tra lại từ khóa "${state.query}"\nhoặc bộ lọc.',
                          actionLabel: 'Xóa từ khóa',
                          onActionPressed: () => _cubit.searchByKeyword(''),
                          buttonColor: colors.success,
                        ),
                      );
                    }
                    return Center(
                      child: _CustomEmptyState(
                        iconData: Icons.assignment_outlined,
                        title: 'Chưa có KH & NCC',
                        description: 'Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.',
                        actionLabel: _canCreate ? 'Thêm KH & NCC' : null,
                        actionLeadingIcon: _canCreate ? Icon(Icons.add, size: 18, color: colors.success) : null,
                        onActionPressed: _canCreate ? _openCreateFlow : null,
                        buttonColor: colors.success,
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

class _CustomEmptyState extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String description;
  final String? actionLabel;
  final Widget? actionLeadingIcon;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final Color? buttonColor;

  const _CustomEmptyState({
    required this.iconData,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionLeadingIcon,
    this.onActionPressed,
    this.iconColor,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VIconBox(
                    iconData: iconData,
                    size: 64,
                    iconSize: 28,
                    backgroundColor: colors.surfaceAlt,
                    iconColor: iconColor ?? colors.textSecondary,
                    borderRadius: VRadius.r16,
                  ),
                  const SizedBox(height: VSpacing.space4),
                  Text(
                    title,
                    style: VTypography.headingH3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VSpacing.space2),
                  Text(
                    description,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (actionLabel != null && onActionPressed != null) ...[
                    const SizedBox(height: VSpacing.space6),
                    VButton(
                      label: actionLabel!,
                      onPressed: onActionPressed!,
                      leadingIcon: actionLeadingIcon,
                      size: VButtonSize.medium,
                      variant: VButtonVariant.outline,
                      foregroundColor: buttonColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
