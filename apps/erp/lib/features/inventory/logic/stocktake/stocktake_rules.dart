import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:vet45_design_system/design_system.dart';

/// Phân tích chuỗi số đếm người dùng nhập; trả null nếu rỗng, âm hoặc không hợp lệ.
num? parseStocktakeCount(String raw) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = num.tryParse(t);
  if (v == null || !v.isFinite || v < 0) return null;
  return v;
}

/// Thông báo chặn nút nộp đếm đầu khi vẫn còn mặt hàng chưa đếm.
String? firstCountBlocker(int missing) =>
    missing > 0 ? 'Còn $missing mặt hàng chưa đếm' : null;

/// Thông báo chặn nút nộp đếm lại khi vẫn còn mặt hàng chưa đếm lại.
String? recountBlocker(int missing) =>
    missing > 0 ? 'Còn $missing mặt hàng chưa đếm lại' : null;

/// Nhãn chênh lệch cho một dòng kiểm kê ở đếm lại và kết quả.
String varianceLabel(num variance, String uom) {
  final kind = variance < 0 ? 'Thiếu' : 'Thừa';
  return '$kind ${formatStockQuantity(variance.abs(), uom)}';
}

/// Lý do mặc định khi dòng có chênh lệch thiếu.
StocktakeLossReason defaultLossReason(StocktakeLine line) =>
    line.isExpired ? StocktakeLossReason.expired : StocktakeLossReason.loss;

/// Dòng phụ tóm tắt tiến độ phiên trên danh sách SCR-042.
String stocktakeListSubtitle(StocktakeListRow row) {
  final tail = switch (row.status) {
    StocktakeStatus.counting => 'Đã đếm ${row.countedCount}/${row.lineCount}',
    StocktakeStatus.recount => '${row.varianceCount} mặt hàng lệch',
    StocktakeStatus.completed =>
      row.varianceCount == 0 ? 'Khớp sổ' : '${row.varianceCount} mặt hàng lệch',
    StocktakeStatus.cancelled => 'Đã hủy',
  };
  return '${row.scopeLabel} · ${row.counterName} · $tail';
}

/// Nhãn và tông màu badge trạng thái phiên kiểm kê.
(String label, VComponentTone tone) stocktakeStatusBadge(
  StocktakeStatus status,
) =>
    switch (status) {
      StocktakeStatus.counting => ('Đang đếm', VComponentTone.info),
      StocktakeStatus.recount => ('Đếm lại', VComponentTone.warning),
      StocktakeStatus.completed => ('Đã xong', VComponentTone.success),
      StocktakeStatus.cancelled => ('Đã hủy', VComponentTone.neutral),
    };

/// Đường dẫn điều hướng tương ứng với trạng thái phiên kiểm kê.
String stocktakeRouteFor(String id, StocktakeStatus status) => switch (status) {
  StocktakeStatus.counting => '/warehouse/stocktakes/$id/count',
  StocktakeStatus.recount => '/warehouse/stocktakes/$id/recount',
  StocktakeStatus.completed ||
  StocktakeStatus.cancelled =>
    '/warehouse/stocktakes/$id/result',
};

/// Dòng phụ của một mặt hàng kiểm kê; dùng NBSP bên trong từng đoạn để tránh ngắt dòng lẻ.
String stocktakeLineSub(StocktakeLine line) {
  final lot = line.lotCode != null
      ? 'Lô\u00a0${line.lotCode}'
      : 'Không\u00a0theo\u00a0lô';
  final state = line.isExpired ? 'Hết\u00a0hạn' : 'Bán\u00a0được';
  return '${line.productCode} · $lot · $state';
}

