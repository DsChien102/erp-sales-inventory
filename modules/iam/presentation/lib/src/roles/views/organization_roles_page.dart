import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/role_ui_model.dart';
import 'organization_role_detail_page.dart';

/// Trang Danh sách Vai trò hệ thống (TA-D-01 & TA-S-02).
///
/// S4 out_of_scope — production routes redirect away; tests pass [initialRoles].
class OrganizationRolesPage extends StatefulWidget {
  final List<RoleUiModel> initialRoles;
  final bool hasError;
  final VoidCallback? onRetry;

  const OrganizationRolesPage({
    super.key,
    this.initialRoles = const [],
    this.hasError = false,
    this.onRetry,
  });

  @override
  State<OrganizationRolesPage> createState() => _OrganizationRolesPageState();
}

class _OrganizationRolesPageState extends State<OrganizationRolesPage> {
  late bool _hasError;

  @override
  void initState() {
    super.initState();
    _hasError = widget.hasError;
  }

  @override
  void didUpdateWidget(covariant OrganizationRolesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError != oldWidget.hasError) {
      setState(() {
        _hasError = widget.hasError;
      });
    }
  }

  Future<void> _navigateToRoleDetail(RoleUiModel role) async {
    try {
      await context.push('/more/roles/detail', extra: role);
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationRoleDetailPage(role: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final roles = widget.initialRoles;

    return VPageScaffold(
      title: 'Vai trò',
      subtitle: _hasError ? 'Không tải được' : '${roles.length} vai trò hệ thống',
      body: _hasError
          ? Center(
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
                          color: colors.dangerBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: VIcon(
                            icon: VIcons.close,
                            size: 28,
                            color: colors.danger,
                          ),
                        ),
                      ),
                      const VGap.md(),
                      VText(
                        'Không thể tải danh sách vai trò',
                        variant: VTextVariant.headingH3,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const VGap.xs(),
                      VText(
                        'Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.',
                        variant: VTextVariant.bodyDefault,
                        color: colors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                      const VGap.md(),
                      GestureDetector(
                        onTap: () {
                          setState(() => _hasError = false);
                          widget.onRetry?.call();
                        },
                        child: VText(
                          'Thử lại',
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              children: [
                // Header section
                VText(
                  'Vai trò hệ thống',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  'Vai trò vận hành không thay đổi tư cách Chủ sở hữu.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),

                // List of roles
                ...roles.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: VSpacing.space3),
                      child: InkWell(
                        onTap: () => _navigateToRoleDetail(role),
                        borderRadius: BorderRadius.circular(VRadius.card),
                        child: Container(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(
                              color: colors.borderDefault,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(VRadius.card),
                          ),
                          child: Row(
                            children: [
                              VIcon(
                                icon: VIcons.person,
                                size: 24,
                                color: colors.textPrimary,
                              ),
                              const VGap.horizontalMd(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    VText(
                                      role.title,
                                      variant: VTextVariant.bodyDefault,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const VGap.xs(),
                                    VText(
                                      '${role.description} · ${role.permissionCount} quyền',
                                      variant: VTextVariant.bodySmall,
                                      color: colors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                              if (role.isCurrent)
                                const VBadge(
                                  label: 'Đang dùng',
                                  tone: VComponentTone.success,
                                  variant: VBadgeVariant.soft,
                                  isSmall: true,
                                )
                              else
                                VIcon(
                                  icon: VIcons.chevronRight,
                                  size: 20,
                                  color: colors.textSecondary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
