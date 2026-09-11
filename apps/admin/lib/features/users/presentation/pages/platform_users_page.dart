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
import '../widgets/platform_users_filter_sheet.dart';

class PlatformUsersPage extends StatelessWidget {
  const PlatformUsersPage({
    super.key,
    this.iamModule,
    this.hasError = false,
    this.isUnauthorized = false,
    this.onUserCountChanged,
  });

  /// Optional override for widget / E2E tests. Defaults to GetIt [IIamModule].
  final IIamModule? iamModule;
  final bool hasError;
  final bool isUnauthorized;
  final ValueChanged<int>? onUserCountChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PlatformUsersCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
          initialState: PlatformUsersState(
            status: isUnauthorized
                ? IamLoadStatus.unauthorized
                : hasError
                ? IamLoadStatus.failure
                : IamLoadStatus.initial,
          ),
        );
        if (!hasError && !isUnauthorized) {
          cubit.load();
        }
        return cubit;
      },
      child: _PlatformUsersView(onUserCountChanged: onUserCountChanged),
    );
  }
}

class _PlatformUsersView extends StatefulWidget {
  const _PlatformUsersView({this.onUserCountChanged});

  final ValueChanged<int>? onUserCountChanged;

  @override
  State<_PlatformUsersView> createState() => _PlatformUsersViewState();
}

class _PlatformUsersViewState extends State<_PlatformUsersView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  static const _filters = <(String, PlatformUserStatus?)>[
    ('Tất cả', null),
    ('Hoạt động', PlatformUserStatus.active),
    ('Chờ kích hoạt', PlatformUserStatus.pendingActivation),
    ('Tạm ngừng', PlatformUserStatus.suspended),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      context.read<PlatformUsersCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocListener<PlatformUsersCubit, PlatformUsersState>(
      listenWhen: (prev, curr) =>
          prev.users.length != curr.users.length || prev.status != curr.status,
      listener: (context, state) {
        if (state.status == IamLoadStatus.success ||
            state.status == IamLoadStatus.empty) {
          widget.onUserCountChanged?.call(state.users.length);
        }
      },
      child: Column(
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
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        context.read<PlatformUsersCubit>().setSearchQuery(
                          value,
                        );
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
                    onTap: () async {
                      final cubit = context.read<PlatformUsersCubit>();
                      final result = await showPlatformUsersFilterSheet(
                        context: context,
                        selected: cubit.state.statusFilter,
                      );
                      if (!context.mounted ||
                          result == null ||
                          !result.applied) {
                        return;
                      }
                      await cubit.setStatusFilter(result.status);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        BlocBuilder<PlatformUsersCubit, PlatformUsersState>(
          buildWhen: (p, c) => p.statusFilter != c.statusFilter,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space1,
              ),
              child: Row(
                children: [
                  for (final entry in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: VSpacing.space2),
                      child: VChip(
                        label: entry.$1,
                        tone: state.statusFilter == entry.$2
                            ? VComponentTone.primary
                            : VComponentTone.neutral,
                        onTap: () => context
                            .read<PlatformUsersCubit>()
                            .setStatusFilter(entry.$2),
                      ),
                    ),
                ],
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
                scrollController: _scrollController,
              );
            },
          ),
        ),
      ],
    ),
    );
  }
}

class _PlatformUsersListBody extends StatelessWidget {
  const _PlatformUsersListBody({
    required this.state,
    required this.searchController,
    required this.scrollController,
  });

  final PlatformUsersState state;
  final TextEditingController searchController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<PlatformUsersCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        Future<void> handleRefresh() => cubit.refresh();

        Widget wrapEmpty(Widget child) {
          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: constraints.maxHeight, child: child),
            ),
          );
        }

        if (state.status == IamLoadStatus.unauthorized) {
          return wrapEmpty(
            PlatformUserEmptyView(
              type: PlatformUserEmptyStateType.unauthorized,
              onAction: cubit.clearUnauthorized,
            ),
          );
        }

        if (state.status == IamLoadStatus.failure) {
          return wrapEmpty(
            PlatformUserEmptyView(
              type: PlatformUserEmptyStateType.loadError,
              onAction: () => cubit.refresh(),
            ),
          );
        }

        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = state.users;
        if (users.isEmpty) {
          final hasQuery =
              state.searchQuery.trim().isNotEmpty || state.statusFilter != null;
          return wrapEmpty(
            PlatformUserEmptyView(
              type: hasQuery
                  ? PlatformUserEmptyStateType.noResults
                  : PlatformUserEmptyStateType.noUsers,
              onAction: hasQuery
                  ? () async {
                      searchController.clear();
                      await cubit.setSearchQuery('');
                      await cubit.setStatusFilter(null);
                    }
                  : () {
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
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space3,
            ),
            itemCount: users.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (context, index) => const VGap.sm(),
            itemBuilder: (context, index) {
              if (index >= users.length) {
                return const Padding(
                  padding: EdgeInsets.all(VSpacing.space4),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final user = users[index];
              final displayName = _platformUserDisplayName(user);
              final primaryText =
                  displayName.isNotEmpty ? displayName : user.email;

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
                            primaryText,
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

  String _platformUserDisplayName(PlatformUserSummaryDto user) {
    final name = user.fullName.trim();
    final email = user.email.trim();
    if (name.isEmpty || name.toLowerCase() == email.toLowerCase()) {
      return '';
    }
    return name;
  }
}
