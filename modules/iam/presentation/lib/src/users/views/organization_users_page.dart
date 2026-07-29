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
import '../widgets/organization_users_widgets.dart';
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

  Future<void> _handleRefresh() async {
    if (_hasError) {
      setState(() => _hasError = false);
    }
    widget.onRetry?.call();
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
                        child: OrganizationUsersTabButton(
                          label: 'Thành viên',
                          isActive: isMemberTab,
                          onTap: () => setState(() => _activeTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: OrganizationUsersTabButton(
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
                            OrganizationUsersFilterChip(
                              label: 'Tất cả',
                              isSelected: _selectedMemberFilter == 'Tất cả',
                              onSelect: (val) {
                                setState(() => _selectedMemberFilter = val);
                              },
                            ),
                            const VGap.horizontalSm(),
                            OrganizationUsersFilterChip(
                              label: 'Hoạt động',
                              isSelected: _selectedMemberFilter == 'Hoạt động',
                              onSelect: (val) {
                                setState(() => _selectedMemberFilter = val);
                              },
                            ),
                            const VGap.horizontalSm(),
                            OrganizationUsersFilterChip(
                              label: 'Tạm ngừng',
                              isSelected: _selectedMemberFilter == 'Tạm ngừng',
                              onSelect: (val) {
                                setState(() => _selectedMemberFilter = val);
                              },
                            ),
                          ]
                        : [
                            OrganizationUsersFilterChip(
                              label: 'Tất cả',
                              isSelected: _selectedInvitationFilter == 'Tất cả',
                              onSelect: (val) {
                                setState(() => _selectedInvitationFilter = val);
                              },
                            ),
                            const VGap.horizontalSm(),
                            OrganizationUsersFilterChip(
                              label: 'Đang chờ',
                              isSelected: _selectedInvitationFilter == 'Đang chờ',
                              onSelect: (val) {
                                setState(() => _selectedInvitationFilter = val);
                              },
                            ),
                            const VGap.horizontalSm(),
                            OrganizationUsersFilterChip(
                              label: 'Sắp hết hạn',
                              isSelected: _selectedInvitationFilter == 'Sắp hết hạn',
                              onSelect: (val) {
                                setState(() => _selectedInvitationFilter = val);
                              },
                            ),
                          ],
                  ),
                ),

                // Main Content area
                Expanded(
                  child: OrganizationUsersMainContent(
                    isUnauthorized: widget.isUnauthorized,
                    hasError: _hasError,
                    isMemberTab: isMemberTab,
                    isFiltered: _isFiltered,
                    members: _filteredMembers,
                    invitations: _filteredInvitations,
                    onRefresh: _handleRefresh,
                    onClearFilter: _clearSearchAndFilter,
                    onInviteMember: _navigateToInviteMember,
                    onErrorRetry: () {
                      setState(() => _hasError = false);
                      widget.onRetry?.call();
                    },
                    onMemberTap: _navigateToMemberDetail,
                    onInvitationTap: _navigateToInvitationDetail,
                  ),
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
                          color: VColors.neutral0,
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
}
