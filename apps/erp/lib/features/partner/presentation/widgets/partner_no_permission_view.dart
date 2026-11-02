import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Màn "không có quyền xem KH & NCC" (key `wgt_e01_u02_fr01_02`).
///
/// Dùng chung cho trang danh sách và shell khu KH & NCC (4-W): shell trả view này
/// cho cả `/partner` lẫn `/partner/:id` khi thiếu `partner.view`.
class PartnerNoPermissionView extends StatelessWidget {
  const PartnerNoPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      key: const Key('wgt_e01_u02_fr01_02'),
      title: 'KH & NCC',
      showBackButton: false,
      body: const Center(
        child: VEmptyState(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VEmptyHeader(
                children: [
                  VEmptyMedia(icon: VIcons.lock),
                  VEmptyTitle('Bạn không có quyền xem\nKH & NCC'),
                  VEmptyDescription(
                    'Liên hệ quản trị viên để được cấp quyền.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
