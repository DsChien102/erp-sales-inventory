import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';

export 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';

enum StockFilter {
  all,
  out,
  low,
  nearExpiry,
  expired;

  String get label => switch (this) {
        StockFilter.all => 'Tất cả',
        StockFilter.out => 'Hết hàng',
        StockFilter.low => 'Tồn thấp',
        StockFilter.nearExpiry => 'Cận hạn',
        StockFilter.expired => 'Hết hạn',
      };

  StockIndicator? get indicator => switch (this) {
        StockFilter.all => null,
        StockFilter.out => StockIndicator.out,
        StockFilter.low => StockIndicator.low,
        StockFilter.nearExpiry => StockIndicator.nearExpiry,
        StockFilter.expired => StockIndicator.expired,
      };
}

/// Tìm kiếm theo tên, mã sản phẩm hoặc mã vạch (`bj01.js:59-60`).
bool matchesSearch(StockOverviewItem p, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return '${p.name} ${p.code} ${p.barcode}'.toLowerCase().contains(q);
}

/// Lọc theo chip và từ khoá; khi `f == StockFilter.all` sắp ổn định theo `urgencyRank` (`bj01.js:217`).
List<StockOverviewItem> visibleProducts(
  List<StockOverviewItem> all,
  StockFilter f,
  String query,
) {
  final ind = f.indicator;
  final filtered = all
      .where(
        (p) =>
            (ind == null || p.indicators.contains(ind)) &&
            matchesSearch(p, query),
      )
      .toList();

  if (f != StockFilter.all) {
    return filtered;
  }

  final indexed = [
    for (var i = 0; i < filtered.length; i++)
      (item: filtered[i], index: i, rank: urgencyRank(filtered[i].indicators)),
  ];
  indexed.sort((a, b) {
    final cmp = a.rank.compareTo(b.rank);
    return cmp != 0 ? cmp : a.index.compareTo(b.index);
  });
  return [for (final entry in indexed) entry.item];
}

/// Đếm số sản phẩm khớp từng chip trên toàn bộ danh sách (không phụ thuộc ô tìm, `bj01.js:102`).
int filterCount(List<StockOverviewItem> all, StockFilter f) {
  final ind = f.indicator;
  if (ind == null) return all.length;
  return all.where((p) => p.indicators.contains(ind)).length;
}

