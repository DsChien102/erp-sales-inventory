import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_users_cubit.dart';
import '../bloc/platform_users_state.dart';

class PlatformUsersPage extends StatelessWidget {
  const PlatformUsersPage({
    super.key,
    this.iamModule,
    this.hasError = false,
    this.isUnauthorized = false,
  });

  /// Optional override for widget / E2E tests. Defaults to GetIt [IIamModule].
  final IIamModule? iamModule;
  final bool hasError;
  final bool isUnauthorized;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PlatformUsersCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
          initialState: PlatformUsersState(
            status: isUnauthorized
                ? PlatformUsersStatus.unauthorized
                : hasError
                ? PlatformUsersStatus.failure
                : PlatformUsersStatus.initial,
          ),
        );
        if (!hasError && !isUnauthorized) {
          cubit.load();
        }
        return cubit;
      },
      child: const _PlatformUsersView(),
    );
  }
}

class _PlatformUsersView extends StatefulWidget {
  const _PlatformUsersView();

  @override
  State<_PlatformUsersView> createState() => _PlatformUsersViewState();
}

class _PlatformUsersViewState extends State<_PlatformUsersView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const _filters = ['Tất cả', 'Hoạt động', 'Chờ kích hoạt', 'Tạm ngừng'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _clearSearchAndReload(BuildContext context) {
    _debounceTimer?.cancel();
    _searchController.clear();
    context.read<PlatformUsersCubit>().resetFiltersAndLoad();
  }

  void _showFilterBottomSheet(BuildContext context) {
    final cubit = context.read<PlatformUsersCubit>();
    var tempStatus = cubit.state.filterStatus;
    var tempActivation = cubit.state.filterActivation;
    var tempEmail = cubit.state.filterEmail;

    showVBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VText(
                  'Bộ lọc người dùng nền tảng',
                  variant: VTextVariant.headingH3,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.lg(),
                VText(
                  'Trạng thái',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.sm(),
                Wrap(
                  spacing: VSpacing.space2,
                  children: [
                    VChip(
                      label: 'Tất cả',
                      emphasis: tempStatus == 0
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempStatus = 0),
                    ),
                    VChip(
                      label: 'Hoạt động',
                      emphasis: tempStatus == 1
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempStatus = 1),
                    ),
                    VChip(
                      label: 'Tạm ngừng',
                      emphasis: tempStatus == 2
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempStatus = 2),
                    ),
                  ],
                ),
                const VGap.md(),
                VText(
                  'Kích hoạt',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.sm(),
                Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space2,
                  children: [
                    VChip(
                      label: 'Tất cả',
                      emphasis: tempActivation == 0
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 0),
                    ),
                    VChip(
                      label: 'Đã kích hoạt',
                      emphasis: tempActivation == 1
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 1),
                    ),
                    VChip(
                      label: 'Chờ kích hoạt',
                      emphasis: tempActivation == 2
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 2),
                    ),
                    VChip(
                      label: 'Hết hạn',
                      emphasis: tempActivation == 3
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 3),
                    ),
                  ],
                ),
                const VGap.md(),
                VText(
                  'Xác minh email',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.sm(),
                Wrap(
                  spacing: VSpacing.space2,
                  children: [
                    VChip(
                      label: 'Tất cả',
                      emphasis: tempEmail == 0
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempEmail = 0),
                    ),
                    VChip(
                      label: 'Đã xác minh',
                      emphasis: tempEmail == 1
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempEmail = 1),
                    ),
                    VChip(
                      label: 'Chưa xác minh',
                      emphasis: tempEmail == 2
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempEmail = 2),
                    ),
                  ],
                ),
                const VGap.xl(),
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Đặt lại',
                        variant: VButtonVariant.outline,
                        onPressed: () {
                          cubit.resetFilters();
                          _searchController.clear();
                          cubit.load(query: '');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: VButton(
                        label: 'Áp dụng',
                        variant: VButtonVariant.primary,
                        onPressed: () {
                          cubit.applyAdvancedFilters(
                            filterStatus: tempStatus,
                            filterActivation: tempActivation,
                            filterEmail: tempEmail,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: VSearchBar(
                  controller: _searchController,
                  hintText: 'Tìm tên hoặc email',
                  onChanged: (value) {
                    if (_debounceTimer?.isActive ?? false) {
                      _debounceTimer!.cancel();
                    }
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        context.read<PlatformUsersCubit>().load(query: value);
                      },
                    );
                  },
                ),
              ),
              const VGap.horizontalSm(),
              BlocBuilder<PlatformUsersCubit, PlatformUsersState>(
                buildWhen: (p, c) => p.isFilterApplied != c.isFilterApplied,
                builder: (context, state) {
                  return VIconBox(
                    icon: VIcons.tune,
                    size: 44,
                    iconSize: 20,
                    backgroundColor: state.isFilterApplied
                        ? colors.successBg
                        : colors.surface,
                    iconColor: state.isFilterApplied
                        ? colors.success
                        : colors.textPrimary,
                    borderColor: state.isFilterApplied
                        ? colors.success
                        : colors.borderDefault,
                    borderRadius: VRadius.button,
                    onTap: () => _showFilterBottomSheet(context),
                  );
                },
              ),
            ],
          ),
        ),
        BlocBuilder<PlatformUsersCubit, PlatformUsersState>(
          buildWhen: (p, c) => p.selectedFilterIndex != c.selectedFilterIndex,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space1,
              ),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = state.selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: VSpacing.space2),
                    child: VChip(
                      label: _filters[index],
                      emphasis: isSelected
                          ? VComponentEmphasis.strong
                          : VComponentEmphasis.medium,
                      onTap: () => context
                          .read<PlatformUsersCubit>()
                          .setSelectedFilterIndex(index),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        Expanded(
          child: BlocBuilder<PlatformUsersCubit, PlatformUsersState>(
            builder: (context, state) {
              return _PlatformUsersListBody(
                state: state,
                searchController: _searchController,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlatformUsersListBody extends StatelessWidget {
  const _PlatformUsersListBody({
    required this.state,
    required this.searchController,
  });

  final PlatformUsersState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<PlatformUsersCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        Future<void> handleRefresh() => cubit.load();

        Widget wrapEmpty(Widget child) {
          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: constraints.maxHeight, child: child),
            ),
          );
        }

        if (state.status == PlatformUsersStatus.unauthorized) {
          return wrapEmpty(
            PlatformUserEmptyView(
              type: PlatformUserEmptyStateType.unauthorized,
              onAction: cubit.clearUnauthorized,
            ),
          );
        }

        if (state.status == PlatformUsersStatus.failure) {
          return wrapEmpty(
            PlatformUserEmptyView(
              type: PlatformUserEmptyStateType.loadError,
              onAction: () => cubit.load(),
            ),
          );
        }

        if (state.status == PlatformUsersStatus.loading ||
            state.status == PlatformUsersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasSearchQuery =
            searchController.text.trim().isNotEmpty ||
            state.searchQuery.trim().isNotEmpty;
        final hasFilter =
            state.selectedFilterIndex != 0 || state.isFilterApplied;
        final isFiltered = hasSearchQuery || hasFilter;

        final users = state.filteredUsers;
        if (users.isEmpty) {
          if (isFiltered) {
            final actionLabel = (hasSearchQuery && !hasFilter)
                ? 'Xóa tìm kiếm'
                : 'Xóa bộ lọc';
            return wrapEmpty(
              PlatformUserEmptyView(
                type: PlatformUserEmptyStateType.noResults,
                customActionLabel: actionLabel,
                onAction: () {
                  searchController.clear();
                  cubit.resetFiltersAndLoad();
                },
              ),
            );
          }
          return wrapEmpty(
            PlatformUserEmptyView(
              type: PlatformUserEmptyStateType.noUsers,
              onAction: () {
                VToast.show(
                  context,
                  title: 'Thông tin',
                  message: 'Mở chức năng thêm người dùng.',
                  type: VToastType.info,
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: handleRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space3,
            ),
            itemCount: users.length,
            separatorBuilder: (context, index) => const VGap.sm(),
            itemBuilder: (context, index) {
              final user = users[index];
              return VCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.space4,
                  vertical: VSpacing.space3,
                ),
                onTap: () {
                  context.pushNamed(
                    'user_detail',
                    pathParameters: {'userId': user.userId},
                  );
                },
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.space1,
                      ),
                      child: VIcon(
                        icon: VIcons.person,
                        size: 24,
                        color: colors.textSecondary,
                      ),
                    ),
                    const VGap.horizontalMd(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            user.fullName,
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const VGap.xs(),
                          VText(
                            'Người dùng nền tảng',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    VIcon(
                      icon: VIcons.chevronRight,
                      color: colors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
