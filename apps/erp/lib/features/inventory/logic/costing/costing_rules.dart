import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';

enum CostStatusTone { success, warning }

class CostRunStatusMeta {
  const CostRunStatusMeta({
    required this.label,
    required this.tone,
    required this.subtitle,
  });

  final String label;
  final CostStatusTone tone;
  final String subtitle;
}

enum CostBlockerAction {
  closePeriod,
  midPeriod,
  stocktakes,
  openPendingRun,
  none,
}

class BlockerView {
  const BlockerView({
    required this.title,
    this.detail,
    this.actionLabel,
    required this.action,
  });

  final String title;
  final String? detail;
  final String? actionLabel;
  final CostBlockerAction action;
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String periodLabel(DateTime month) {
  return '${_pad2(month.month)}/${month.year}';
}

String formatDateDdMmYyyy(DateTime dt) {
  return '${_pad2(dt.day)}/${_pad2(dt.month)}/${dt.year}';
}

String formatDateTimeDdMmYyyyHm(DateTime dt) {
  return '${formatDateDdMmYyyy(dt)} · ${_pad2(dt.hour)}:${_pad2(dt.minute)}';
}

String runTitle(CostRunKind kind, DateTime month) {
  final p = periodLabel(month);
  return kind == CostRunKind.periodClose
      ? 'Chốt kỳ $p'
      : 'Cập nhật giá vốn $p';
}

String runSubtitle(CostRunView run) {
  final cutoff = formatDateTimeDdMmYyyyHm(run.cutOffAt);
  if (run.productCount <= 0) {
    return 'Thời điểm chốt $cutoff';
  }
  return '${run.productCount} sản phẩm · Thời điểm chốt $cutoff';
}

String signedMoney(int v) {
  if (v == 0) return '0 đ';
  final grouped = MoneyFormatter.formatMinorPlain(v.abs());
  return v > 0 ? '+$grouped đ' : '\u2212$grouped đ';
}

String moneyWithSpace(int v) {
  final grouped = MoneyFormatter.formatMinorPlain(v.abs());
  return v < 0 ? '\u2212$grouped đ' : '$grouped đ';
}

CostRunStatusMeta runStatus(CostRunRow r) {
  return switch (r.status) {
    CostRunStatus.readyForReview => CostRunStatusMeta(
        label: 'Sẵn sàng công bố',
        tone: CostStatusTone.success,
        subtitle: '${r.productCount} sản phẩm · đã tính, chờ công bố',
      ),
    CostRunStatus.published => CostRunStatusMeta(
        label: 'Đã công bố',
        tone: CostStatusTone.success,
        subtitle: r.publishedAt != null
            ? 'Công bố ${formatDateDdMmYyyy(r.publishedAt!)}'
            : 'Đã công bố',
      ),
    CostRunStatus.stale => CostRunStatusMeta(
        label: 'Cần tính lại',
        tone: CostStatusTone.warning,
        subtitle: '${r.productCount} sản phẩm · dữ liệu đã đổi',
      ),
    CostRunStatus.blocked || CostRunStatus.superseded => CostRunStatusMeta(
        label: 'Cần xử lý',
        tone: CostStatusTone.warning,
        subtitle: '${r.blockerCount} việc cần xử lý',
      ),
  };
}

BlockerView blockerView(CostBlocker b) {
  final p = b.periodMonth != null ? periodLabel(b.periodMonth!) : '';
  return switch (b.code) {
    'PREVIOUS_PERIOD_OPEN' => BlockerView(
        title: 'Kỳ $p chưa chốt',
        actionLabel: 'Chốt kỳ $p',
        action: CostBlockerAction.closePeriod,
      ),
    'PERIOD_NOT_ENDED' => BlockerView(
        title: 'Tháng $p chưa kết thúc',
        actionLabel: 'Cập nhật giữa kỳ',
        action: CostBlockerAction.midPeriod,
      ),
    'STOCKTAKE_OPEN' => const BlockerView(
        title: 'Có phiên kiểm kê chưa ghi nhận',
        actionLabel: 'Mở kiểm kê',
        action: CostBlockerAction.stocktakes,
      ),
    'RUN_PENDING_REVIEW' => const BlockerView(
        title: 'Đã có lần tính chờ công bố',
        actionLabel: 'Mở lần tính',
        action: CostBlockerAction.openPendingRun,
      ),
    'LEDGER_MISMATCH' => BlockerView(
        title:
            'Sổ số lượng và sổ giá trị không khớp (${b.productCount ?? 0} sản phẩm)',
        detail: 'Liên hệ hỗ trợ; không tự sửa.',
        action: CostBlockerAction.none,
      ),
    'NOTHING_TO_COST' || _ => const BlockerView(
        title: 'Không có biến động mới từ lần công bố trước',
        action: CostBlockerAction.none,
      ),
  };
}

List<CostRunLineView> topChanged(List<CostRunLineView> lines, int n) {
  return lines.where((l) => l.lineAdjust != 0).take(n).toList(growable: false);
}

(String label, String sentence) methodCopy(CostMethod m) {
  return m == CostMethod.periodic
      ? (
          'Bình quân cuối kỳ',
          'giá vốn mỗi sản phẩm là giá trung bình của tồn đầu kỳ và hàng nhập cả kỳ.',
        )
      : (
          'Bình quân liên hoàn',
          'giá vốn tính lại sau mỗi lần nhập.',
        );
}

