import '../shared/entity_type.dart';
import '../shared/partner_role.dart';
import '../shared/partner_status.dart';
import '../shared/profile_category.dart';
import 'search_keyword_normalizer.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

enum PartnerRoleFilter {
  customer,
  supplier,
  both,
}

enum PartnerSortOrder {
  updatedAtDesc,
}

final class PartnerSearchCriteria extends ValueObject {
  PartnerSearchCriteria({
    String? keyword,
    Set<PartnerStatus>? statuses,
    this.roleFilter,
    this.entityType,
    this.profileCategory,
    this.sortOrder = PartnerSortOrder.updatedAtDesc,
  })  : keyword = SearchKeywordNormalizer.normalizeKeyword(keyword),
        statuses = statuses == null || statuses.isEmpty
            ? {PartnerStatus.active}
            : Set.unmodifiable(statuses) {
    if (entityType != null && profileCategory != null) {
      throw DomainException(
        'Only one of entityType or profileCategory may be specified.',
      );
    }
  }

  final String? keyword;
  final Set<PartnerStatus> statuses;
  final PartnerRoleFilter? roleFilter;
  final EntityType? entityType;
  final ProfileCategory? profileCategory;
  final PartnerSortOrder sortOrder;

  bool get activeOnly =>
      statuses.length == 1 && statuses.contains(PartnerStatus.active);

  Set<EntityType>? get expandedEntityTypes {
    if (entityType != null) {
      return {entityType!};
    }
    if (profileCategory == null) {
      return null;
    }
    return switch (profileCategory!) {
      ProfileCategory.individual => {EntityType.individual},
      ProfileCategory.organization => {
          EntityType.householdBusiness,
          EntityType.company,
        },
    };
  }

  Set<PartnerRole> get effectiveRoles {
    return switch (roleFilter) {
      PartnerRoleFilter.customer => {PartnerRole.customer},
      PartnerRoleFilter.supplier => {PartnerRole.supplier},
      PartnerRoleFilter.both => {
          PartnerRole.customer,
          PartnerRole.supplier,
        },
      null => <PartnerRole>{},
    };
  }

  @override
  List<Object?> get props => [
        keyword,
        statuses.toList()..sort((a, b) => a.name.compareTo(b.name)),
        roleFilter,
        entityType,
        profileCategory,
        sortOrder,
      ];
}
