import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum SalesOrderDetailErrorKind { blocked, notFound, projectionPending, error }

class SalesOrderDetailErrorState extends StatelessWidget {
  const SalesOrderDetailErrorState({
    super.key,
    required this.kind,
    this.message,
    this.onRetry,
    this.onBack,
  });

  final SalesOrderDetailErrorKind kind;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(kind);
    final effectiveDesc = message == null || message!.isEmpty ? spec.description : message!;
    final action = onRetry != null ? spec.retryLabel : (onBack != null ? 'Quay lại' : null);
    final onAction = onRetry ?? onBack;

    return Center(
      child: VEmptyState(
        key: spec.key,
        tone: spec.tone,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VEmptyHeader(
              children: [
                VEmptyMedia(icon: spec.icon),
                VEmptyTitle(spec.title),
                VEmptyDescription(effectiveDesc),
              ],
            ),
            if (action != null && onAction != null) ...[
              const VGap.sm(),
              VEmptyContent(
                child: VButton(
                  label: action,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ErrorSpec _specFor(SalesOrderDetailErrorKind kind) {
    return switch (kind) {
      SalesOrderDetailErrorKind.blocked => const _ErrorSpec(
        key: Key('wgt_sg08_blocked'),
        icon: VIcons.warning,
        tone: VComponentTone.warning,
        title: 'Không có quyền xem đơn hàng',
        description: 'Tài khoản của bạn không có quyền xem đơn hàng này.',
        retryLabel: 'Thử lại',
      ),
      SalesOrderDetailErrorKind.notFound => const _ErrorSpec(
        key: Key('wgt_sg08_not_found'),
        icon: VIcons.info,
        tone: VComponentTone.neutral,
        title: 'Không tìm thấy đơn hàng',
        description: 'Đơn hàng không tồn tại hoặc đã bị xóa.',
        retryLabel: 'Thử lại',
      ),
      SalesOrderDetailErrorKind.projectionPending => const _ErrorSpec(
        key: Key('wgt_sg08_projection_pending'),
        icon: VIcons.info,
        tone: VComponentTone.warning,
        title: 'Đơn hàng đang cập nhật',
        description: 'Dữ liệu đơn hàng chưa sẵn sàng. Vui lòng thử lại.',
        retryLabel: 'Thử lại',
      ),
      SalesOrderDetailErrorKind.error => const _ErrorSpec(
        key: Key('wgt_sg08_error'),
        icon: VIcons.warning,
        tone: VComponentTone.danger,
        title: 'Không thể tải chi tiết đơn hàng',
        description: 'Kiểm tra kết nối và thử lại.',
        retryLabel: 'Thử lại',
      ),
    };
  }
}

class _ErrorSpec {
  const _ErrorSpec({
    required this.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
    required this.retryLabel,
  });

  final Key key;
  final VIcons icon;
  final VComponentTone tone;
  final String title;
  final String description;
  final String retryLabel;
}
