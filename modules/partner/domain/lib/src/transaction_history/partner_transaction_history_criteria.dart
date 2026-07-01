import '../search/search_keyword_normalizer.dart';
import '../shared/partner_role.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerTransactionHistoryCriteria extends ValueObject {
  PartnerTransactionHistoryCriteria({
    String? keyword,
    Set<String>? transactionTypes,
    this.transactionRole,
    this.from,
    this.to,
  })  : keyword = SearchKeywordNormalizer.normalizeKeyword(keyword),
        transactionTypes = transactionTypes == null || transactionTypes.isEmpty
            ? null
            : Set.unmodifiable(transactionTypes) {
    if (from != null && to != null && from!.isAfter(to!)) {
      throw DomainException(
        'Transaction history date range is invalid: from must be on or before to.',
      );
    }
  }

  final String? keyword;
  final Set<String>? transactionTypes;
  final PartnerRole? transactionRole;
  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [
        keyword,
        transactionTypes == null
            ? null
            : (transactionTypes!.toList()..sort()),
        transactionRole,
        from,
        to,
      ];
}
