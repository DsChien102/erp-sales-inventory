import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space4,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              VCard(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Nhật ký thao tác',
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.sm(),
                      VText(
                        'Lịch sử và nhật ký thao tác đặc quyền của hệ thống sẽ hiển thị ở đây.',
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
