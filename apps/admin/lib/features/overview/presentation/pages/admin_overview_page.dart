import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

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
                        'Tổng quan quản trị',
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.sm(),
                      VText(
                        'Khung giao diện tổng quan hệ thống. Nội dung chi tiết các chỉ số (Người dùng nền tảng, Tổ chức đang quản lý, Thao tác đặc quyền, Hoạt động gần đây) sẽ được thêm tại bước tiếp theo.',
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
