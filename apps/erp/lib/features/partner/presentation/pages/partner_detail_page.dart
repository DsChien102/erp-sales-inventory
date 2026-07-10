import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerDetailPage extends StatefulWidget {
  const PartnerDetailPage({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
    this.showCreateSuccessToast = false,
  });

  final String partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final bool showCreateSuccessToast;

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  late final PartnerDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerDetailCubit(
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
    )..loadDetail(widget.partnerId);

    if (widget.showCreateSuccessToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPartnerCreateSuccessToast(context);
      });
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showActionSheet(BuildContext context, PartnerDetailDto dto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerDetailActionSheet(
        dto: dto,
        onActionSelected: (action) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hành động ${action.name} sẽ có ở bản cập nhật tiếp theo.'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('wgt_e01_u04_fr01_01'),
        backgroundColor: colors.surface,
        appBar: const VAppBar(
          title: 'Hồ sơ KH & NCC',
          showBackButton: true,
        ),
        body: BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
          builder: (context, state) {
            if (state is PartnerDetailLoading || state is PartnerDetailInitial) {
              return const PartnerDetailLoadingSkeleton();
            }

            if (state is PartnerDetailError) {
              if (state.isNoPermission) {
                return Center(
                  child: PartnerDetailErrorState(
                    iconData: Icons.lock_outline_rounded,
                    title: 'Không có quyền xem hồ sơ',
                    description: 'Bạn không có quyền truy cập hồ sơ\nKhách hàng & Nhà cung cấp.',
                    actionLabel: 'Quay lại',
                    onActionPressed: () => context.pop(),
                  ),
                );
              }
              if (state.isNotFound) {
                return Center(
                  child: PartnerDetailErrorState(
                    iconData: Icons.search_off_rounded,
                    title: 'Không tìm thấy hồ sơ',
                    description: 'Hồ sơ có thể đã bị xóa hoặc không tồn tại\nhoặc bạn không có quyền xem.',
                    actionLabel: 'Quay lại',
                    onActionPressed: () => context.pop(),
                  ),
                );
              }
              return Center(
                child: PartnerDetailErrorState(
                  iconData: Icons.cloud_off_rounded,
                  title: 'Không tải được hồ sơ',
                  description: 'Vui lòng kiểm tra kết nối internet hoặc thử lại sau.',
                  actionLabel: 'Thử lại',
                  onActionPressed: () => _cubit.loadDetail(widget.partnerId),
                ),
              );
            }

            if (state is PartnerDetailLoaded) {
              final dto = state.dto;
              final isPerson = dto.partnerType == PartnerType.person;
              final phone = isPerson ? dto.personProfile?.phone : dto.organizationProfile?.phone;
              final taxCode = isPerson ? dto.personProfile?.taxCode : dto.organizationProfile?.taxCode;
              final hasWarning = isPerson
                  ? (dto.personProfile?.taxCode == null || dto.personProfile?.invoice == null)
                  : (dto.organizationProfile?.taxCode == null || dto.organizationProfile?.invoice == null);

              final List<String> contactParts = [];
              if (phone != null && phone.isNotEmpty) contactParts.add(phone);
              if (taxCode != null && taxCode.isNotEmpty) contactParts.add('MST $taxCode');
              final contactInfoText = contactParts.join('  •  ');

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _cubit.loadDetail(widget.partnerId),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(VSpacing.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header layout (Initials, Name, classify, status tag)
                            _buildHeader(context, dto),
                            const SizedBox(height: VSpacing.space4),

                            // Phone & MST Quick-Action
                            if (contactInfoText.isNotEmpty) ...[
                              _buildPhoneAction(context, contactInfoText),
                              const SizedBox(height: VSpacing.space4),
                            ],

                            // Warning Banner (D-03)
                            if (hasWarning && dto.status == PartnerStatus.active) ...[
                              _buildWarningBanner(context),
                              const SizedBox(height: VSpacing.space4),
                            ],

                            // Inactive Banner (D-04)
                            if (dto.status == PartnerStatus.inactive) ...[
                              _buildInactiveBanner(context),
                              const SizedBox(height: VSpacing.space4),
                            ],

                            // Info Cards
                            _buildInfoTile(
                              context,
                              title: 'Thông tin chính',
                              icon: Icons.assignment_ind_outlined,
                              onTap: () {},
                            ),
                            const SizedBox(height: VSpacing.space2),

                            // Contacts Card (Only for Org)
                            if (!isPerson) ...[
                              PartnerDetailContactsCard(
                                dto: dto,
                                onTapHeader: () {},
                                onTapViewAll: () {},
                              ),
                              const SizedBox(height: VSpacing.space2),
                            ],

                            _buildInfoTile(
                              context,
                              title: 'Hóa đơn / thuế',
                              icon: Icons.receipt_long_outlined,
                              trailingText: hasWarning ? 'Thiếu MST, địa chỉ' : null,
                              trailingColor: hasWarning ? colors.danger : null,
                              onTap: () {},
                            ),
                            const SizedBox(height: VSpacing.space2),

                            _buildInfoTile(
                              context,
                              title: 'Địa chỉ giao hàng',
                              icon: Icons.location_on_outlined,
                              trailingText: (isPerson ? dto.personProfile?.delivery == null : dto.organizationProfile?.delivery == null)
                                  ? 'Chưa có'
                                  : null,
                              trailingColor: colors.warning,
                              onTap: () {},
                            ),
                            const SizedBox(height: VSpacing.space2),

                            _buildInfoTile(
                              context,
                              title: 'Lịch sử gần đây',
                              icon: Icons.history_toggle_off_rounded,
                              trailingText: '3', // Seed data has 3 history records
                              onTap: () {},
                            ),
                            const SizedBox(height: VSpacing.space2),

                            _buildInfoTile(
                              context,
                              title: 'Thông tin hệ thống',
                              icon: Icons.settings_outlined,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer buttons (D-01 to D-04 layout) with Safe Area inside container
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(top: BorderSide(color: colors.borderDefault)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          VSpacing.space4,
                          VSpacing.space3,
                          VSpacing.space4,
                          VSpacing.space4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: VButton(
                                label: 'Chỉnh sửa',
                                variant: VButtonVariant.outline,
                                foregroundColor: colors.success,
                                onPressed: () {
                                  // Action to navigate to edit page (Slice 4)
                                },
                              ),
                            ),
                            const SizedBox(width: VSpacing.space3),
                            Expanded(
                              child: VButton(
                                label: 'Thao tác  ▲',
                                variant: VButtonVariant.primary,
                                onPressed: () => _showActionSheet(context, dto),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    int sum = 0;
    for (int i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  Widget _buildHeader(BuildContext context, PartnerDetailDto dto) {
    final colors = context.vColors;
    final isPerson = dto.partnerType == PartnerType.person;
    final labelType = isPerson ? 'Cá nhân' : 'Tổ chức';
    final labelRoles = dto.roles.contains(PartnerRoleType.customer) && dto.roles.contains(PartnerRoleType.supplier)
        ? 'KH & NCC'
        : (dto.roles.contains(PartnerRoleType.customer) ? 'Khách hàng' : 'Nhà cung cấp');

    // Initials Avatar
    final initials = dto.displayName.trim().split(RegExp(r'\s+'));
    final avatarText = initials.isEmpty ? '?' : (initials.length == 1 ? initials[0][0] : '${initials[0][0]}${initials.last[0]}').toUpperCase();

    // Use exact same avatar color algorithm as list page
    final avatarBgColor = _getAvatarColor(dto.displayName);

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: avatarBgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            avatarText,
            style: VTypography.headingH2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: VSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dto.displayName,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$labelType • $labelRoles',
                style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 6),
              if (dto.status == PartnerStatus.active)
                _buildStatusTag(context, 'Đang hoạt động', colors.success)
              else if (dto.status == PartnerStatus.inactive)
                _buildStatusTag(context, 'Ngừng hoạt động', colors.warning),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: VTypography.bodySmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPhoneAction(BuildContext context, String text) {
    final colors = context.vColors;
    return Row(
      children: [
        Icon(Icons.phone_outlined, size: 20, color: colors.textSecondary),
        const SizedBox(width: VSpacing.space3),
        Expanded(
          child: Text(
            text,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 22),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ sơ còn thiếu thông tin',
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thiếu MST và địa chỉ hóa đơn. Một số thông tin có thể cần bổ sung trong tính năng này.',
                  style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Bổ sung ngay',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: colors.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBanner(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 22),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ sơ đang ngừng hoạt động',
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Không được chọn cho giao dịch mới như bán hàng, nhập hàng hoặc công nợ.',
                  style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? trailingText,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    final colors = context.vColors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.card),
        side: BorderSide(color: colors.borderDefault),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: 0),
        leading: Icon(icon, color: colors.textSecondary, size: 20),
        title: Text(
          title,
          style: VTypography.bodyDefault.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trailingColor?.withValues(alpha: 0.1) ?? colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingText,
                  style: VTypography.bodySmall.copyWith(
                    color: trailingColor ?? colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
