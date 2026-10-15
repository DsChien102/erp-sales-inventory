import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Trang không có quyền (mọi màn BJ-02). Không dựng dữ liệu nghiệp vụ nào.
class InventoryPermissionDenied extends StatelessWidget {
  const InventoryPermissionDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(VSpacing.space6),
        child: VEmptyState(
          child: VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.lock),
              VEmptyTitle('Không có quyền truy cập'),
              VEmptyDescription(
                'Dữ liệu nghiệp vụ không được tải vào màn hình này. Liên hệ quản trị viên nếu cần cấp quyền.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum InventoryNotice { conflict, locked, readOnly, validation, stale }

class InventoryNoticeBanner extends StatelessWidget {
  const InventoryNoticeBanner(this.notice, {super.key, this.action});

  final InventoryNotice notice;

  /// Đặt vào `VBanner.footer`, vd `VButton('Tải lại')`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (status, title, description) = switch (notice) {
      InventoryNotice.conflict => (
        VBannerStatus.warning,
        'Dữ liệu vừa thay đổi',
        'Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng.',
      ),
      InventoryNotice.locked => (
        VBannerStatus.warning,
        'Kho đang được khóa',
        'Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết.',
      ),
      InventoryNotice.readOnly => (
        VBannerStatus.info,
        'Chế độ chỉ xem',
        'Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa.',
      ),
      InventoryNotice.validation => (
        VBannerStatus.error,
        'Cần kiểm tra dữ liệu',
        'Dữ liệu đã nhập được giữ lại. Sửa trường được đánh dấu trước khi tiếp tục.',
      ),
      InventoryNotice.stale => (
        VBannerStatus.warning,
        'Dữ liệu có thể đã cũ',
        'Làm mới lịch sử trước khi dựa vào trạng thái hiện tại.',
      ),
    };
    return VBanner(
      status: status,
      title: title,
      description: description,
      footer: action,
    );
  }
}
