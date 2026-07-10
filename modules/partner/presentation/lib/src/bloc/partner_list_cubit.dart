import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'partner_list_state.dart';

final class PartnerListCubit extends Cubit<PartnerListState> {
  PartnerListCubit({
    required IPartnerModule partnerModule,
    required IExecutionContext executionContext,
  }) : _partnerModule = partnerModule,
       _executionContext = executionContext,
       super(const PartnerListInitial());

  final IPartnerModule _partnerModule;
  final IExecutionContext _executionContext;

  static const int _pageSize = 20;

  int? _nextPage;
  String? _query;

  Future<void> fetchPartners({bool isRefresh = false, String? query}) async {
    try {
      if (query != null) {
        _query = query.trim().isEmpty ? null : query.trim();
      }
      if (isRefresh) {
        _nextPage = 1;
      }

      final currentState = state;
      final currentItems = switch (currentState) {
        PartnerListLoaded(:final items) when !isRefresh => items,
        PartnerListLoading(:final items) when !isRefresh => items,
        _ => <PartnerListItemDto>[],
      };

      if (!isRefresh && currentState is PartnerListLoaded && currentState.hasReachedMax) {
        return;
      }

      emit(
        PartnerListLoading(
          items: isRefresh ? const [] : currentItems,
          isFirstLoad: isRefresh || currentItems.isEmpty,
          query: _query,
        ),
      );

      final tenantId = await _executionContext.requireTenantId();
      final page = _nextPage ?? 1;
      final result = await _partnerModule.executeQueryAsync(
        SearchPartnersQuery(
          tenantId: tenantId,
          query: _query,
          status: PartnerStatus.active,
          page: page,
          limit: _pageSize,
        ),
      );

      final newItems = isRefresh ? result.items : [...currentItems, ...result.items];
      final hasReachedMax = newItems.length >= result.total || result.items.isEmpty;
      _nextPage = hasReachedMax ? null : page + 1;

      emit(
        PartnerListLoaded(
          items: newItems,
          total: result.total,
          hasReachedMax: hasReachedMax,
          query: _query,
        ),
      );
    } catch (error) {
      emit(PartnerListError(error.toString()));
    }
  }

  void searchByKeyword(String keyword) {
    fetchPartners(isRefresh: true, query: keyword);
  }
}
