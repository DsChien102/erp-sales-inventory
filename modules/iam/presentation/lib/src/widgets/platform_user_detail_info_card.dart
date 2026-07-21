import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class PlatformUserDetailInfoCard extends StatelessWidget {
  const PlatformUserDetailInfoCard({super.key, required this.user});

  final PlatformUserDetailDto user;

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Thông tin tài khoản',
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const VGap.md(),
          if (user.status == PlatformUserStatus.active) ...[
            _buildInfoRow(
              label: 'Email đã xác minh',
              value: user.emailVerified
                  ? _formatDateTime(user.createdAt.add(const Duration(hours: 8, minutes: 5)))
                  : 'Chưa xác minh',
              colors: colors,
            ),
            if (user.lastLoginAt != null) ...[
              const VGap.md(),
              _buildInfoRow(
                label: 'Đăng nhập gần nhất',
                value: _formatDateTime(user.lastLoginAt!),
                colors: colors,
              ),
            ],
            const VGap.md(),
            _buildInfoRow(
              label: 'Ngày tạo tài khoản',
              value: _formatDateTime(user.createdAt),
              colors: colors,
            ),
          ] else if (user.status == PlatformUserStatus.pendingActivation) ...[
            _buildInfoRow(
              label: 'Email đã xác minh',
              value: 'Chưa xác minh',
              colors: colors,
            ),
            const VGap.md(),
            _buildInfoRow(
              label: 'Ngày tạo tài khoản',
              value: _formatDateTime(user.createdAt),
              colors: colors,
            ),
            const VGap.md(),
            _buildInfoRow(
              label: 'Email kích hoạt hết hạn',
              value: _formatDateTime(
                user.createdAt.add(const Duration(days: 3)),
              ),
              colors: colors,
            ),
          ] else if (user.status == PlatformUserStatus.suspended) ...[
            _buildInfoRow(
              label: 'Email đã xác minh',
              value: user.emailVerified ? _formatDateTime(user.createdAt) : 'Chưa xác minh',
              colors: colors,
            ),
            if (user.lastLoginAt != null) ...[
              const VGap.md(),
              _buildInfoRow(
                label: 'Ngày tạm ngừng',
                value: _formatDateTime(user.lastLoginAt!),
                colors: colors,
              ),
            ],
            const VGap.md(),
            _buildInfoRow(
              label: 'Lý do',
              value: 'Theo yêu cầu quản trị',
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required VColorScheme colors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodyDefault,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
