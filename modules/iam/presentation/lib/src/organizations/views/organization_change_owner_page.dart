import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';
import '../widgets/organization_change_owner_confirmation_bottom_sheet.dart';

/// Trang Thay đổi chủ sở hữu cho tổ chức.
class OrganizationChangeOwnerPage extends StatefulWidget {
  final OrganizationUiModel organization;
  final VoidCallback? onOwnerChanged;

  /// When set, confirmation calls this with the selected member id.
  final Future<bool> Function(String newOwnerUserId)? onConfirmTransfer;

  const OrganizationChangeOwnerPage({
    super.key,
    required this.organization,
    this.onOwnerChanged,
    this.onConfirmTransfer,
  });

  @override
  State<OrganizationChangeOwnerPage> createState() => _OrganizationChangeOwnerPageState();
}

class _OrganizationChangeOwnerPageState extends State<OrganizationChangeOwnerPage> {
  final TextEditingController _searchController = TextEditingController();
  late List<OrganizationMemberUiModel> _members;
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _members = widget.organization.members;
    _selectedMemberId = _members.isEmpty ? null : _members.first.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrganizationMemberUiModel> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _members;
    return _members.where((m) {
      return m.name.toLowerCase().contains(query) ||
          m.email.toLowerCase().contains(query) ||
          m.role.toLowerCase().contains(query);
    }).toList();
  }

  OrganizationMemberUiModel? get _selectedMember {
    try {
      return _members.firstWhere((m) => m.id == _selectedMemberId);
    } catch (_) {
      return _members.isNotEmpty ? _members.first : null;
    }
  }

  void _showConfirmation(BuildContext context) {
    final member = _selectedMember;
    if (member == null) return;

    showVBottomSheet(
      context: context,
      child: OrganizationChangeOwnerConfirmationBottomSheet(
        member: member,
        onConfirm: () async {
          final transfer = widget.onConfirmTransfer;
          if (transfer != null) {
            final ok = await transfer(member.id);
            if (!context.mounted) return;
            if (ok) {
              widget.onOwnerChanged?.call();
              Navigator.of(context).pop(true);
            }
            return;
          }
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final filtered = _filteredMembers;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Thay đổi chủ sở hữu',
        showBackButton: true,
        leading: IconButton(
          icon: VIcon(
            icon: VIcons.arrowLeft,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ô tìm kiếm dùng VSearchBar từ Design System
            VSearchBar(
              controller: _searchController,
              hintText: 'Tìm tên hoặc email',
              variant: VSearchBarVariant.outlined,
              onChanged: (_) => setState(() {}),
            ),
            const VGap.md(),

            // Tiêu đề phần chọn
            VText(
              'Chọn thành viên đang hoạt động',
              variant: VTextVariant.headingH4,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            VText(
              'Vai trò hiện hành của thành viên sẽ được giữ nguyên.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.md(),

            if (filtered.isEmpty)
              VText(
                _members.isEmpty
                    ? 'Chưa có thành viên đang hoạt động'
                    : 'Không tìm thấy thành viên phù hợp',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              )
            else
              ...filtered.map((member) {
                final isSelected = member.id == _selectedMemberId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.space3),
                  child: _MemberRadioCard(
                    member: member,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedMemberId = member.id;
                      });
                    },
                  ),
                );
              }),
            const VGap.xl(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.borderDefault),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  label: 'Hủy',
                  variant: VButtonVariant.outline,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VButton(
                  label: 'Tiếp tục',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.success,
                  fullWidth: true,
                  onPressed: _selectedMember != null ? () => _showConfirmation(context) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRadioCard extends StatelessWidget {
  final OrganizationMemberUiModel member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberRadioCard({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderColor = isSelected ? colors.primary : colors.borderDefault;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r16),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(VRadius.r16),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Initials Avatar Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceBrand : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r12),
                ),
                alignment: Alignment.center,
                child: VText(
                  member.resolvedInitials,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.primary : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      member.name,
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (member.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      VText(
                        member.email,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                    const SizedBox(height: 2),
                    VText(
                      member.role,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Radio Circle Indicator
              _RadioCircle(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  final bool isSelected;

  const _RadioCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (isSelected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
          ),
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.borderStrong,
          width: 1.5,
        ),
      ),
    );
  }
}
