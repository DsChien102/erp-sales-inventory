import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

/// Bộ lọc nâng cao D-03 (SG-01).
final class PriceRuleAdvancedFilter {
  const PriceRuleAdvancedFilter({
    this.status,
    this.warning,
    this.source,
    this.updatedWithin,
  });

  /// null = Tất cả
  final CustomerPriceRuleDerivedStatus? status;

  /// null = Tất cả
  final PriceRuleWarningFilter? warning;

  /// null = Tất cả
  final CustomerPriceRuleSourceType? source;

  /// null = không lọc theo thời gian
  final PriceRuleUpdatedWithin? updatedWithin;

  static const empty = PriceRuleAdvancedFilter();

  bool get hasActiveFilters =>
      status != null ||
      warning != null ||
      source != null ||
      updatedWithin != null;

  int get activeCount {
    var count = 0;
    if (status != null) count++;
    if (warning != null) count++;
    if (source != null) count++;
    if (updatedWithin != null) count++;
    return count;
  }

  PriceRuleAdvancedFilter copyWith({
    Object? status = _sentinel,
    Object? warning = _sentinel,
    Object? source = _sentinel,
    Object? updatedWithin = _sentinel,
  }) {
    return PriceRuleAdvancedFilter(
      status: identical(status, _sentinel)
          ? this.status
          : status as CustomerPriceRuleDerivedStatus?,
      warning: identical(warning, _sentinel)
          ? this.warning
          : warning as PriceRuleWarningFilter?,
      source: identical(source, _sentinel)
          ? this.source
          : source as CustomerPriceRuleSourceType?,
      updatedWithin: identical(updatedWithin, _sentinel)
          ? this.updatedWithin
          : updatedWithin as PriceRuleUpdatedWithin?,
    );
  }
}

const _sentinel = Object();

enum PriceRuleWarningFilter { belowFloor, duplicateRule, dataError }

enum PriceRuleUpdatedWithin { last7Days, last30Days }

/// Sắp xếp D-05 (SG-01).
enum PriceRuleSortOption {
  updatedAtDesc,
  updatedAtAsc,
  customerNameAsc,
  customerNameDesc,
  priceDesc,
  priceAsc,
  warningsFirst,
}

extension PriceRuleSortOptionLabel on PriceRuleSortOption {
  String get label => switch (this) {
    PriceRuleSortOption.updatedAtDesc => 'Cập nhật gần nhất',
    PriceRuleSortOption.updatedAtAsc => 'Cập nhật cũ nhất',
    PriceRuleSortOption.customerNameAsc => 'Tên khách hàng A-Z',
    PriceRuleSortOption.customerNameDesc => 'Tên khách hàng Z-A',
    PriceRuleSortOption.priceDesc => 'Giá riêng cao → thấp',
    PriceRuleSortOption.priceAsc => 'Giá riêng thấp → cao',
    PriceRuleSortOption.warningsFirst => 'Cảnh báo cần xử lý trước',
  };
}
