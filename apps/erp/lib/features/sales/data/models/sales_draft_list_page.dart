import 'package:erp/features/sales/data/models.dart';

final class SalesDraftListEntry {
  const SalesDraftListEntry({
    required this.draft,
    required this.createdByUserId,
    this.createdByName,
  });

  final SalesOrderDraftDto draft;
  final String createdByUserId;
  final String? createdByName;
}

final class SalesDraftListPage {
  const SalesDraftListPage({
    required this.items,
    required this.hasMore,
    required this.totalCount,
    this.nextCursor,
  });

  final List<SalesDraftListEntry> items;
  final bool hasMore;
  final int totalCount;
  final String? nextCursor;
}

