import 'package:equatable/equatable.dart';
import 'package:vet45_partner_application/application.dart';

sealed class PartnerListState extends Equatable {
  const PartnerListState();

  @override
  List<Object?> get props => [];
}

final class PartnerListInitial extends PartnerListState {
  const PartnerListInitial();
}

final class PartnerListLoading extends PartnerListState {
  const PartnerListLoading({
    required this.items,
    this.isFirstLoad = true,
    this.query,
  });

  final List<PartnerListItemDto> items;
  final bool isFirstLoad;
  final String? query;

  @override
  List<Object?> get props => [items, isFirstLoad, query];
}

final class PartnerListLoaded extends PartnerListState {
  const PartnerListLoaded({
    required this.items,
    required this.total,
    required this.hasReachedMax,
    this.query,
  });

  final List<PartnerListItemDto> items;
  final int total;
  final bool hasReachedMax;
  final String? query;

  @override
  List<Object?> get props => [items, total, hasReachedMax, query];
}

final class PartnerListError extends PartnerListState {
  const PartnerListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
