import 'package:vet45_design_system/design_system.dart';

/// 5 loại chỉ báo tồn theo đặc tả Theme 7 (bj01.js / cap01.js).
enum StockIndicator {
  out,
  expired,
  low,
  nearExpiry,
  notConfigured,
}

extension StockIndicatorX on StockIndicator {
  String get label => switch (this) {
        StockIndicator.out => 'Hết hàng',
        StockIndicator.expired => 'Có lô hết hạn',
        StockIndicator.low => 'Tồn thấp',
        StockIndicator.nearExpiry => 'Có lô cận hạn',
        StockIndicator.notConfigured => 'Chưa có ngưỡng tồn',
      };

  VComponentTone? get tone => switch (this) {
        StockIndicator.out => VComponentTone.danger,
        StockIndicator.expired => VComponentTone.danger,
        StockIndicator.low => VComponentTone.warning,
        StockIndicator.nearExpiry => VComponentTone.warning,
        StockIndicator.notConfigured => null,
      };
}

/// Tính toàn bộ chỉ báo tồn của một sản phẩm theo thứ tự bj01Indicators.
List<StockIndicator> stockIndicators({
  required num available,
  required num? threshold,
  required bool hasExpired,
  required bool hasNearExpiry,
}) {
  final res = <StockIndicator>[];

  if (available == 0) {
    res.add(StockIndicator.out);
  }
  if (hasExpired) {
    res.add(StockIndicator.expired);
  }
  if (threshold != null && available > 0 && available <= threshold) {
    res.add(StockIndicator.low);
  }
  if (hasNearExpiry) {
    res.add(StockIndicator.nearExpiry);
  }
  if (threshold == null) {
    res.add(StockIndicator.notConfigured);
  }

  return res;
}

/// Chỉ báo ưu tiên chính theo bj01PrimaryAttention.
StockIndicator? primaryIndicator(
  List<StockIndicator> all, {
  StockIndicator? filter,
}) {
  if (filter != null) {
    if (all.contains(filter)) {
      return filter;
    }
    if (all.contains(StockIndicator.notConfigured)) {
      return StockIndicator.notConfigured;
    }
    return null;
  }

  const priority = [
    StockIndicator.out,
    StockIndicator.expired,
    StockIndicator.low,
    StockIndicator.nearExpiry,
    StockIndicator.notConfigured,
  ];

  for (final ind in priority) {
    if (all.contains(ind)) {
      return ind;
    }
  }

  return null;
}

/// Mức gấp theo thứ tự sắp xếp bj01UrgencyRank.
int urgencyRank(List<StockIndicator> all) {
  const urgency = [
    StockIndicator.out,
    StockIndicator.expired,
    StockIndicator.low,
    StockIndicator.nearExpiry,
  ];

  for (var i = 0; i < urgency.length; i++) {
    if (all.contains(urgency[i])) {
      return i;
    }
  }

  if (all.contains(StockIndicator.notConfigured)) {
    return urgency.length + 1; // 5
  }

  return urgency.length; // 4 (bình thường)
}
