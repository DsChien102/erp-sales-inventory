import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../testing/fake_users_data.dart';
import '../models/user_ui_model.dart';
import '../widgets/invitation_card.dart';
import '../widgets/invitation_filter_bottom_sheet.dart';
import '../widgets/member_card.dart';
import '../widgets/member_filter_bottom_sheet.dart';
import 'organization_invitation_detail_page.dart';
import 'organization_invite_member_page.dart';
import 'organization_member_detail_page.dart';

/// Trang Danh sách người dùng & Lời mời (TA-D-01 & TA-D-02, TA-S-01, TA-S-02, TA-S-03).
class OrganizationUsersPage extends StatefulWidget {
  final List<MemberUiModel> initialMembers;
  final List<InvitationUiModel> initialInvitations;
  final bool hasError;
  final bool isUnauthorized;
  final VoidCallback? onRetry;

  const OrganizationUsersPage({
    super.key,
    this.initialMembers = FakeUsersData.sampleMembers,
    this.initialInvitations = FakeUsersData.sampleInvitations,
    this.hasError = false,
    this.isUnauthorized = false,
    this.onRetry,
  });

  @override
  State<OrganizationUsersPage> createState() => _OrganizationUsersPageState();
}

class _OrganizationUsersPageState extends State<OrganizationUsersPage> {
  int _activeTabIndex = 0; // 0: Thành viên, 1: Lời mời

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // Filter chips selection
  String _selectedMemberFilter = 'Tất cả';
  String _selectedInvitationFilter = 'Tất cả';

  MemberFilterCriteria _memberFilterCriteria = const MemberFilterCriteria();
  InvitationFilterCriteria _invitationFilterCriteria = const InvitationFilterCriteria();

  late bool _hasError;

  @override
  void initState() {
    super.initState();
    _hasError = widget.hasError;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrganizationUsersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError != oldWidget.hasError) {
      setState(() {
        _hasError = widget.hasError;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFiltered {
    final isMemberTab = _activeTabIndex == 0;
    final activeFilter = isMemberTab ? _selectedMemberFilter : _selectedInvitationFilter;
    return _searchQuery.isNotEmpty || activeFilter != 'Tất cả';
  }

  void _clearSearchAndFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMemberFilter = 'Tất cả';
      _selectedInvitationFilter = 'Tất cả';
      _memberFilterCriteria = const MemberFilterCriteria();
      _invitationFilterCriteria = const InvitationFilterCriteria();
    });
  }

  List<MemberUiModel> get _filteredMembers {
    var result = widget.initialMembers.where((member) {
      final statusFilter = _memberFilterCriteria.status != 'Tất cả'
          ? _memberFilterCriteria.status
          : _selectedMemberFilter;
      if (statusFilter == 'Hoạt động' && member.status != MemberStatus.active) {
        return false;
      }
      if (statusFilter == 'Tạm ngừng' && member.status != MemberStatus.suspended) {
        return false;
      }

      if (_memberFilterCriteria.role != 'Tất cả') {
        if (!member.role.contains(_memberFilterCriteria.role)) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final nameMatch = member.name.toLowerCase().contains(_searchQuery);
        final emailMatch = member.email.toLowerCase().contains(_searchQuery);
        return nameMatch || emailMatch;
      }
      return true;
    }).toList();

    if (_memberFilterCriteria.sort == 'Tên A–Z') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_memberFilterCriteria.sort == 'Tên Z–A') {
      result.sort((a, b) => b.name.compareTo(a.name));
    }

    return result;
  }

  List<InvitationUiModel> get _filteredInvitations {
    return widget.initialInvitations.where((invitation) {
      final statusFilter = _invitationFilterCriteria.status != 'Tất cả'
          ? _invitationFilterCriteria.status
          : _selectedInvitationFilter;
      if (statusFilter == 'Đang chờ' && invitation.status != InvitationStatus.pending) {
        return false;
      }
      if (statusFilter == 'Sắp hết hạn' && invitation.status != InvitationStatus.expiring) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final emailMatch = invitation.email.toLowerCase().contains(_searchQuery);
        final roleMatch = invitation.role.toLowerCase().contains(_searchQuery);
        return emailMatch || roleMatch;
      }
      return true;
    }).toList();
  }

  Future<void> _navigateToInviteMember() async {
    dynamic result;
    try {
      result = await context.push('/more/users/invite');
    } catch (_) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OrganizationInviteMemberPage(),
        ),
      );
    }
    if (result == true && mounted) {
      VToast.show(
        context,
        title: 'Đã thu hồi lời mời.',
        message: '',
        type: VToastType.success,
      );
    }
  }

  Future<void> _openFilterBottomSheet() async {
    if (_activeTabIndex == 0) {
      final newCriteria = await showVBottomSheet<MemberFilterCriteria>(
        context: context,
        child: MemberFilterBottomSheet(
          initialCriteria: _memberFilterCriteria,
        ),
      );
      if (newCriteria != null && mounted) {
        setState(() {
          _memberFilterCriteria = newCriteria;
        });
      }
    } else {
      final newCriteria = await showVBottomSheet<InvitationFilterCriteria>(
        context: context,
        child: InvitationFilterBottomSheet(
          initialCriteria: _invitationFilterCriteria,
        ),
      );
      if (newCriteria != null && mounted) {
        setState(() {
          _invitationFilterCriteria = newCriteria;
        });
      }
    }
  }

  Future<void> _navigateToInvitationDetail(InvitationUiModel invitation) async {
    dynamic result;
    try {
      result = await context.push('/more/users/invitation-detail', extra: invitation);
    } catch (_) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationInvitationDetailPage(invitation: invitation),
        ),
      );
    }
    if (result == true && mounted) {
      VToast.show(
        context,
        title: 'Đã thu hồi lời mời.',
        message: '',
        type: VToastType.success,
      );
    }
  }

  Future<void> _navigateToMemberDetail(MemberUiModel member) async {
    try {
      await context.push('/more/users/member-detail', extra: member);
    } catch (_) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationMemberDetailPage(member: member),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isMemberTab = _activeTabIndex == 0;
    final memberCount = _filteredMembers.length;
    final invitationCount = _filteredInvitations.length;
    final currentCount = isMemberTab ? memberCount : invitationCount;

    final isFilterActive = isMemberTab
        ? (_memberFilterCriteria.isFilterActive || _selectedMemberFilter != 'Tất cả')
        : (_invitationFilterCriteria.isFilterActive || _selectedInvitationFilter != 'Tất cả');

    final String subtitleText;
    if (widget.isUnauthorized) {
      subtitleText = 'Chưa cấp quyền';
    } else if (_hasError) {
      subtitleText = 'Không tải được';
    } else if (_isFiltered && currentCount == 0) {
      subtitleText = '0 kết quả';
    } else {
      subtitleText = isMemberTab ? '$memberCount thành viên' : '$invitationCount lời mời';
    }

    return VPageScaffold(
      title: 'Người dùng',
      subtitle: subtitleText,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Column(
              children: [
                // Search & Filter bar area
                Container(
                  color: colors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.screenMobile,
                    vertical: VSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: VSearchBar(
                          hintText: 'Tìm tên hoặc email',
                          controller: _searchController,
                        ),
                      ),
                      const VGap.horizontalSm(),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: isFilterActive
                              ? colors.primary.withValues(alpha: 0.1)
                              : colors.surface,
                          border: Border.all(
                            color: isFilterActive ? colors.primary : colors.borderDefault,
                          ),
                          borderRadius: BorderRadius.circular(VRadius.button),
                        ),
                        child: IconButton(
                          icon: VIcon(
                            icon: VIcons.tune,
                            size: 20,
                            color: isFilterActive ? colors.primary : colors.textPrimary,
                          ),
                          onPressed: _openFilterBottomSheet,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab header (Thành viên / Lời mời)
                Container(
                  color: colors.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          label: 'Thành viên',
                          isActive: isMemberTab,
                          onTap: () => setState(() => _activeTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          label: 'Lời mời',
                          isActive: !isMemberTab,
                          onTap: () => setState(() => _activeTabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.borderDefault),

                // Filter Chips row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.screenMobile,
                    vertical: VSpacing.space3,
                  ),
                  child: Row(
                    children: isMemberTab
                        ? [
                            _buildFilterChip('Tất cả', _selectedMemberFilter == 'Tất cả', (val) {
                              setState(() => _selectedMemberFilter = val);
                            }),
                            const VGap.horizontalSm(),
                            _buildFilterChip('Hoạt động', _selectedMemberFilter == 'Hoạt động', (
                              val,
                            ) {
                              setState(() => _selectedMemberFilter = val);
                            }),
                            const VGap.horizontalSm(),
                            _buildFilterChip('Tạm ngừng', _selectedMemberFilter == 'Tạm ngừng', (
                              val,
                            ) {
                              setState(() => _selectedMemberFilter = val);
                            }),
                          ]
                        : [
                            _buildFilterChip('Tất cả', _selectedInvitationFilter == 'Tất cả', (
                              val,
                            ) {
                              setState(() => _selectedInvitationFilter = val);
                            }),
                            const VGap.horizontalSm(),
                            _buildFilterChip('Đang chờ', _selectedInvitationFilter == 'Đang chờ', (
                              val,
                            ) {
                              setState(() => _selectedInvitationFilter = val);
                            }),
                            const VGap.horizontalSm(),
                            _buildFilterChip(
                              'Sắp hết hạn',
                              _selectedInvitationFilter == 'Sắp hết hạn',
                              (val) {
                                setState(() => _selectedInvitationFilter = val);
                              },
                            ),
                          ],
                  ),
                ),

                // Main Content area
                Expanded(
                  child: _buildMainContent(colors, isMemberTab),
                ),
              ],
            ),

            // Floating Action Button (+) (Ẩn ở tab Thành viên)
            if (!widget.isUnauthorized && !isMemberTab)
              Positioned(
                right: VSpacing.screenMobile,
                bottom: MediaQuery.of(context).padding.bottom + VSpacing.space4,
                child: Material(
                  color: Colors.transparent,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _navigateToInviteMember,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: VIcon(
                          icon: VIcons.add,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    widget.onRetry?.call();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _hasError = false;
      });
    }
  }

  Widget _buildScrollableEmptyState(Widget emptyStateWidget) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 480,
          alignment: Alignment.center,
          child: emptyStateWidget,
        ),
      ),
    );
  }

  Widget _buildMainContent(dynamic colors, bool isMemberTab) {
    // Unauthorized / Permission denied state (matching Image 1 design & app/admin)
    if (widget.isUnauthorized) {
      return _buildScrollableEmptyState(
        _buildEmptyState(
          icon: VIcons.shield,
          iconBgColor: colors.warningBg,
          iconColor: colors.warning,
          title: 'Bạn không có quyền quản lý',
          subtitle: 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.',
          actionText: 'Quay lại',
          actionColor: colors.success,
          onAction: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    }

    // TA-S-03 Error state
    if (_hasError) {
      return _buildScrollableEmptyState(
        _buildEmptyState(
          icon: VIcons.close,
          iconBgColor: colors.dangerBg,
          iconColor: colors.danger,
          title: 'Không thể tải danh sách',
          titleColor: colors.danger,
          subtitle: 'Đã xảy ra lỗi khi tải thành viên. Vui lòng thử lại.',
          actionText: 'Thử lại',
          actionColor: colors.danger,
          onAction: () {
            setState(() => _hasError = false);
            widget.onRetry?.call();
          },
        ),
      );
    }

    if (isMemberTab) {
      if (_filteredMembers.isEmpty) {
        if (_isFiltered) {
          // TA-S-02 Search / Filter empty state
          return _buildScrollableEmptyState(
            _buildEmptyState(
              icon: VIcons.search,
              title: 'Không tìm thấy kết quả',
              subtitle: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
              actionText: 'Xóa bộ lọc',
              onAction: _clearSearchAndFilter,
            ),
          );
        }
        // TA-S-01 Empty state
        return _buildScrollableEmptyState(
          _buildEmptyState(
            icon: VIcons.info,
            title: 'Chưa có thành viên khác',
            subtitle: 'Mời thêm người dùng để cùng vận hành tổ chức.',
            actionText: 'Mời thành viên',
            onAction: _navigateToInviteMember,
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: VSpacing.screenMobile,
            right: VSpacing.screenMobile,
            bottom: 80,
          ),
          itemCount: _filteredMembers.length,
          separatorBuilder: (_, __) => const VGap.sm(),
          itemBuilder: (context, index) {
            final member = _filteredMembers[index];
            return MemberCard(
              member: member,
              onTap: () => _navigateToMemberDetail(member),
            );
          },
        ),
      );
    }

    // Invitation tab
    if (_filteredInvitations.isEmpty) {
      if (_isFiltered) {
        // TA-S-02 Search / Filter empty state
        return _buildScrollableEmptyState(
          _buildEmptyState(
            icon: VIcons.search,
            title: 'Không tìm thấy kết quả',
            subtitle: 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.',
            actionText: 'Xóa bộ lọc',
            onAction: _clearSearchAndFilter,
          ),
        );
      }
      // TA-S-01 Empty state
      return _buildScrollableEmptyState(
        _buildEmptyState(
          icon: VIcons.info,
          title: 'Chưa có lời mời nào',
          subtitle: 'Tạo lời mời mới để thêm người dùng vào tổ chức.',
          actionText: 'Mời thành viên',
          onAction: _navigateToInviteMember,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: VSpacing.screenMobile,
          right: VSpacing.screenMobile,
          bottom: 80,
        ),
        itemCount: _filteredInvitations.length,
        separatorBuilder: (_, __) => const VGap.sm(),
        itemBuilder: (context, index) {
          final invitation = _filteredInvitations[index];
          return InvitationCard(
            invitation: invitation,
            onTap: () => _navigateToInvitationDetail(invitation),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.success : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodyDefault,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    ValueChanged<String> onSelect,
  ) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space3,
          vertical: VSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.successBg : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: isSelected ? colors.success : colors.borderDefault,
          ),
        ),
        child: VText(
          label,
          variant: VTextVariant.bodySmall,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.success : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required VIcons icon,
    Color? iconBgColor,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required String actionText,
    Color? actionColor,
    required VoidCallback onAction,
  }) {
    final colors = context.vColors;
    return Align(
      alignment: const Alignment(0, -0.85),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
        child: VCard(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space5,
            vertical: VSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor ?? colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: VIcon(
                    icon: icon,
                    size: 28,
                    color: iconColor ?? colors.textSecondary,
                  ),
                ),
              ),
              const VGap.md(),
              VText(
                title,
                variant: VTextVariant.headingH4,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? colors.textPrimary,
                ),
              ),
              const VGap.xs(),
              VText(
                subtitle,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.md(),
              GestureDetector(
                onTap: onAction,
                child: VText(
                  actionText,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: actionColor ?? colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
