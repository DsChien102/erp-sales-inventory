import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../mock_platform_service.dart';

class PlatformUsersPage extends StatefulWidget {
  final bool hasError;
  final bool isUnauthorized;

  const PlatformUsersPage({
    super.key,
    this.hasError = false,
    this.isUnauthorized = false,
  });

  @override
  State<PlatformUsersPage> createState() => _PlatformUsersPageState();
}

class _PlatformUsersPageState extends State<PlatformUsersPage> {
  int _selectedFilterIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // BottomSheet Filter selections
  int _filterStatus = 0; // 0: Tất cả, 1: Hoạt động, 2: Tạm ngừng
  int _filterActivation = 0; // 0: Tất cả, 1: Đã kích hoạt, 2: Chờ kích hoạt, 3: Hết hạn
  int _filterEmail = 0; // 0: Tất cả, 1: Đã xác minh, 2: Chưa xác minh

  late bool _hasError = widget.hasError;
  late bool _isUnauthorized = widget.isUnauthorized;

  Timer? _debounceTimer;

  bool get _isFilterApplied =>
      _filterStatus != 0 || _filterActivation != 0 || _filterEmail != 0;

  final List<String> _filters = [
    'Tất cả',
    'Hoạt động',
    'Chờ kích hoạt',
    'Tạm ngừng',
  ];

  PlatformUserStatus? _getStatusForIndex(int index) {
    switch (index) {
      case 1:
        return PlatformUserStatus.active;
      case 2:
        return PlatformUserStatus.pendingActivation;
      case 3:
        return PlatformUserStatus.suspended;
      default:
        return null;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    int tempStatus = _filterStatus;
    int tempActivation = _filterActivation;
    int tempEmail = _filterEmail;

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
                      emphasis: tempStatus == 0 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempStatus = 0),
                    ),
                    VChip(
                      label: 'Hoạt động',
                      emphasis: tempStatus == 1 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempStatus = 1),
                    ),
                    VChip(
                      label: 'Tạm ngừng',
                      emphasis: tempStatus == 2 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
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
                      emphasis: tempActivation == 0 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 0),
                    ),
                    VChip(
                      label: 'Đã kích hoạt',
                      emphasis: tempActivation == 1 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 1),
                    ),
                    VChip(
                      label: 'Chờ kích hoạt',
                      emphasis: tempActivation == 2 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempActivation = 2),
                    ),
                    VChip(
                      label: 'Hết hạn',
                      emphasis: tempActivation == 3 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
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
                      emphasis: tempEmail == 0 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempEmail = 0),
                    ),
                    VChip(
                      label: 'Đã xác minh',
                      emphasis: tempEmail == 1 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                      onTap: () => setSheetState(() => tempEmail = 1),
                    ),
                    VChip(
                      label: 'Chưa xác minh',
                      emphasis: tempEmail == 2 ? VComponentEmphasis.strong : VComponentEmphasis.medium,
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
                          setState(() {
                            _filterStatus = 0;
                            _filterActivation = 0;
                            _filterEmail = 0;
                            _selectedFilterIndex = 0;
                            _searchQuery = '';
                            _searchController.clear();
                          });
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
                          setState(() {
                            _filterStatus = tempStatus;
                            _filterActivation = tempActivation;
                            _filterEmail = tempEmail;
                            if (tempStatus == 0) {
                              _selectedFilterIndex = 0;
                            } else if (tempStatus == 1) {
                              _selectedFilterIndex = 1;
                            } else if (tempStatus == 2) {
                              _selectedFilterIndex = 3;
                            }
                          });
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
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final service = MockPlatformService.instance;

    return Column(
      children: [
        // Thanh tìm kiếm và bộ lọc nâng cao
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
                    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                      setState(() {
                        _searchQuery = value;
                      });
                    });
                  },
                ),
              ),
              const VGap.horizontalSm(),
              VIconBox(
                icon: VIcons.tune,
                size: 44,
                iconSize: 20,
                backgroundColor: _isFilterApplied ? colors.successBg : colors.surface,
                iconColor: _isFilterApplied ? colors.success : colors.textPrimary,
                borderColor: _isFilterApplied ? colors.success : colors.borderDefault,
                borderRadius: VRadius.button,
                onTap: () => _showFilterBottomSheet(context),
              ),
            ],
          ),
        ),

        // Các chip bộ lọc trạng thái ngang
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space1,
          ),
          child: Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _selectedFilterIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: VSpacing.space2),
                child: VChip(
                  label: _filters[index],
                  emphasis: isSelected ? VComponentEmphasis.strong : VComponentEmphasis.medium,
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
        ),

        // Danh sách người dùng
        Expanded(
          child: ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  Future<void> handleRefresh() async {
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) {
                      setState(() {});
                    }
                  }

                  Widget wrapEmpty(Widget child) {
                    return RefreshIndicator(
                      onRefresh: handleRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: child,
                        ),
                      ),
                    );
                  }

                  // 1. Check unauthorized first
                  if (_isUnauthorized) {
                    return wrapEmpty(
                      PlatformUserEmptyView(
                        type: PlatformUserEmptyStateType.unauthorized,
                        onAction: () {
                          setState(() {
                            _isUnauthorized = false;
                          });
                        },
                      ),
                    );
                  }

                  // 2. Check load error
                  if (_hasError) {
                    return wrapEmpty(
                      PlatformUserEmptyView(
                        type: PlatformUserEmptyStateType.loadError,
                        onAction: () {
                          setState(() {
                            _hasError = false;
                          });
                        },
                      ),
                    );
                  }

                  // 3. Filter list
                  final users = service.searchPlatformUsers(
                    query: _searchQuery,
                  ).where((userSummary) {
                    final user = service.getPlatformUser(userSummary.userId);
                    if (user == null) return false;

                    // Apply horizontal chip
                    final statusFilter = _getStatusForIndex(_selectedFilterIndex);
                    if (statusFilter != null && user.status != statusFilter) {
                      return false;
                    }

                    // Apply bottom sheet status
                    if (_filterStatus == 1 && user.status != PlatformUserStatus.active) return false;
                    if (_filterStatus == 2 && user.status != PlatformUserStatus.suspended) return false;

                    // Apply bottom sheet activation
                    if (_filterActivation == 1 &&
                        (user.status != PlatformUserStatus.active && user.status != PlatformUserStatus.suspended)) {
                      return false;
                    }
                    if (_filterActivation == 2 && user.status != PlatformUserStatus.pendingActivation) return false;
                    if (_filterActivation == 3) return false;

                    // Apply bottom sheet email
                    if (_filterEmail == 1 && !user.emailVerified) return false;
                    if (_filterEmail == 2 && user.emailVerified) return false;

                    return true;
                  }).toList();

                  // 4. Check empty states
                  if (users.isEmpty) {
                    // Check if the service has no users at all (raw database empty)
                    final rawUsers = service.searchPlatformUsers();
                    if (rawUsers.isEmpty) {
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
                    } else {
                      return wrapEmpty(
                        PlatformUserEmptyView(
                          type: PlatformUserEmptyStateType.noResults,
                          onAction: () {
                            setState(() {
                              _filterStatus = 0;
                              _filterActivation = 0;
                              _filterEmail = 0;
                              _searchQuery = '';
                              _searchController.clear();
                              _selectedFilterIndex = 0;
                            });
                          },
                        ),
                      );
                    }
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
                                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space1),
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
            },
          ),
        ),
      ],
    );
  }
}
