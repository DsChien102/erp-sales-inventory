import 'package:equatable/equatable.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

sealed class PartnerContactsState extends Equatable {
  const PartnerContactsState();

  @override
  List<Object?> get props => [];
}

class PartnerContactsInitial extends PartnerContactsState {
  const PartnerContactsInitial();
}

class PartnerContactsLoading extends PartnerContactsState {
  const PartnerContactsLoading();
}

class PartnerContactsLoaded extends PartnerContactsState {
  const PartnerContactsLoaded({
    required this.organization,
    this.searchQuery = '',
    this.actionError,
    this.isActionLoading = false,
  });

  final PartnerDetailDto organization;
  final String searchQuery;
  final String? actionError;
  final bool isActionLoading;

  List<PartnerContactDto> get filteredContacts {
    final list = organization.contacts;
    if (searchQuery.trim().isEmpty) return list;

    final q = searchQuery.toLowerCase().trim();
    return list.where((c) {
      final nameMatches = c.displayName.toLowerCase().contains(q);
      final phoneMatches = c.phone?.toLowerCase().contains(q) ?? false;
      final emailMatches = c.email?.toLowerCase().contains(q) ?? false;
      return nameMatches || phoneMatches || emailMatches;
    }).toList();
  }

  PartnerContactsLoaded copyWith({
    PartnerDetailDto? organization,
    String? searchQuery,
    String? actionError,
    bool? isActionLoading,
  }) {
    return PartnerContactsLoaded(
      organization: organization ?? this.organization,
      searchQuery: searchQuery ?? this.searchQuery,
      actionError: actionError,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  @override
  List<Object?> get props => [organization, searchQuery, actionError, isActionLoading];
}

class PartnerContactsError extends PartnerContactsState {
  const PartnerContactsError(this.message, {this.isNoPermission = false});

  final String message;
  final bool isNoPermission;

  @override
  List<Object?> get props => [message, isNoPermission];
}
