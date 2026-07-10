import 'package:equatable/equatable.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

enum PartnerRoleFilter { customer, supplier, both }

enum PartnerSortOption {
  updatedAtDesc,
  updatedAtAsc,
  nameAsc,
  nameDesc,
  roleAsc,
  roleDesc,
}

sealed class PartnerListState extends Equatable {
  const PartnerListState({
    this.query,
    this.partnerType,
    this.roleFilter,
    this.status,
    this.sortOption = PartnerSortOption.updatedAtDesc,
  });

  final String? query;
  final PartnerType? partnerType;
  final PartnerRoleFilter? roleFilter;
  final PartnerStatus? status;
  final PartnerSortOption sortOption;

  @override
  List<Object?> get props => [query, partnerType, roleFilter, status, sortOption];
}

final class PartnerListInitial extends PartnerListState {
  const PartnerListInitial();
}

final class PartnerListLoading extends PartnerListState {
  const PartnerListLoading({
    required this.items,
    this.isFirstLoad = true,
    super.query,
    super.partnerType,
    super.roleFilter,
    super.status,
    super.sortOption = PartnerSortOption.updatedAtDesc,
  });

  final List<PartnerListItemDto> items;
  final bool isFirstLoad;

  @override
  List<Object?> get props => [
        items,
        isFirstLoad,
        ...super.props,
      ];
}

final class PartnerListLoaded extends PartnerListState {
  const PartnerListLoaded({
    required this.items,
    required this.total,
    required this.hasReachedMax,
    super.query,
    super.partnerType,
    super.roleFilter,
    super.status,
    super.sortOption = PartnerSortOption.updatedAtDesc,
  });

  final List<PartnerListItemDto> items;
  final int total;
  final bool hasReachedMax;

  @override
  List<Object?> get props => [
        items,
        total,
        hasReachedMax,
        ...super.props,
      ];
}

final class PartnerListError extends PartnerListState {
  const PartnerListError(
    this.message, {
    super.query,
    super.partnerType,
    super.roleFilter,
    super.status,
    super.sortOption = PartnerSortOption.updatedAtDesc,
  });

  final String message;

  @override
  List<Object?> get props => [
        message,
        ...super.props,
      ];
}
