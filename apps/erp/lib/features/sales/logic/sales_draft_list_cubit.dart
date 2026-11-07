import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/logic/sales_draft_error_messages.dart';
import 'package:erp/features/sales/logic/sales_draft_list_state.dart';
import 'package:erp/features/sales/presentation/models/sales_order_draft/sales_draft_list_item_vm.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_shared_application/application.dart';

final class SalesDraftListCubit extends Cubit<SalesDraftListState> {
  SalesDraftListCubit({
    required SalesDraftRepository repository,
    required IExecutionContext executionContext,
    required ISalesActiveStoreContext activeStoreContext,
  }) : _repository = repository,
       _executionContext = executionContext,
       _activeStoreContext = activeStoreContext,
       super(const SalesDraftListInitial());

  final SalesDraftRepository _repository;
  final IExecutionContext _executionContext;
  final ISalesActiveStoreContext _activeStoreContext;

  String? _query;
  String? _discardingDraftId;
  SalesDraftScopeFilter _scope = SalesDraftScopeFilter.mine;
  int _generation = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  Future<void> setScope(SalesDraftScopeFilter scope) async {
    if (isClosed) return;
    if (_scope == scope) return;
    _scope = scope;
    await load(isRefresh: true, force: true);
  }

  Future<void> searchByKeyword(String query) async {
    if (isClosed) return;
    final q = query.trim().isEmpty ? null : query.trim();
    if (q == _query) return;
    _query = q;
    await load(isRefresh: true, force: true);
  }

  Future<void> clearSearch() async {
    await searchByKeyword('');
  }

  Future<void> load({bool isRefresh = false, bool force = false}) async {
    if (isClosed) return;
    if (_isLoading && !force) return;
    _isLoading = true;
    final gen = ++_generation;
    try {
      await _load(isRefresh: isRefresh, gen: gen);
    } finally {
      if (gen == _generation) {
        _isLoading = false;
      }
    }
  }

  Future<void> _load({required bool isRefresh, required int gen}) async {
    final current = state;
    final retain = switch (current) {
      SalesDraftListLoaded(:final items) when !isRefresh => items,
      SalesDraftListLoading(:final items) when !isRefresh => items,
      _ => const <SalesDraftListItemVm>[],
    };

    emit(
      SalesDraftListLoading(
        items: isRefresh ? const [] : retain,
        isFirstLoad: isRefresh || retain.isEmpty,
        query: _query,
        isCreating: current.isCreating,
        discardingDraftId: _discardingDraftId,
        needsReload: false,
        actionMessage: null,
        totalCount: current.totalCount,
        scope: _scope,
      ),
    );

    try {
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed || gen != _generation) return;

      final page = await _repository.list(
        storeId: storeId,
        pageSize: 25,
        search: _query,
        createdByUserId: _scope == SalesDraftScopeFilter.mine ? actorId : null,
      );
      if (isClosed || gen != _generation) return;

      final items = _mapEntries(page.items, currentUserId: actorId);

      emit(
        SalesDraftListLoaded(
          items: items,
          isDefaultEmpty: items.isEmpty && _query == null,
          query: _query,
          isCreating: current.isCreating,
          discardingDraftId: _discardingDraftId,
          needsReload: false,
          actionMessage: null,
          totalCount: page.totalCount,
          scope: _scope,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || gen != _generation) return;
      if (error.code == SalesDraftErrorCodes.noPermission ||
          error.code == SalesDraftErrorCodes.dataScopeDenied) {
        emit(
          SalesDraftListBlocked(
            message: salesDraftErrorMessage(error, fallback: 'Không thể tải danh sách đơn nháp'),
            scope: _scope,
          ),
        );
        return;
      }
      emit(
        SalesDraftListError(
          'Không thể tải danh sách đơn nháp',
          query: _query,
          totalCount: current.totalCount,
          scope: _scope,
        ),
      );
    } catch (_) {
      if (isClosed || gen != _generation) return;
      emit(
        SalesDraftListError(
          'Không thể tải danh sách đơn nháp',
          query: _query,
          totalCount: current.totalCount,
          scope: _scope,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (isClosed) return;
    if (_isLoading || _isLoadingMore) return;
    final current = state;
    if (current is! SalesDraftListLoaded) return;
    if (!current.hasMore || current.nextCursor == null) return;

    _isLoadingMore = true;
    final gen = _generation;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed || gen != _generation) return;

      final page = await _repository.list(
        storeId: storeId,
        cursor: current.nextCursor,
        pageSize: 25,
        search: _query,
        createdByUserId: _scope == SalesDraftScopeFilter.mine ? actorId : null,
      );
      if (isClosed || gen != _generation) return;

      final newItems = _mapEntries(page.items, currentUserId: actorId);
      final combined = [...current.items, ...newItems];

      emit(
        current.copyWith(
          items: combined,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || gen != _generation) return;
      emit(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: salesDraftErrorMessage(error, fallback: 'Không thể tải thêm đơn nháp'),
        ),
      );
    } catch (_) {
      if (isClosed || gen != _generation) return;
      emit(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: 'Không thể tải thêm đơn nháp',
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  List<SalesDraftListItemVm> _mapEntries(
    List<SalesDraftListEntry> entries, {
    required String currentUserId,
  }) {
    return entries
        .map((entry) {
          final d = entry.draft;
          final customer = d.customer;
          final isOwnedByMe = entry.createdByUserId == currentUserId;
          return SalesDraftListItemVm(
            draftId: d.draftId,
            version: d.version,
            updatedAt: d.savedAt,
            customerLabel: customer?.displayName ?? 'Khách lẻ',
            phone: customer?.phoneNumber,
            note: d.orderNote,
            lineCount: d.lines.length,
            total: d.total,
            uiStatus: d.needsRevalidation
                ? SalesDraftUiStatus.needsCheck
                : SalesDraftUiStatus.composing,
            warningMessage: null,
            createdByName: entry.createdByName,
            isOwnedByMe: isOwnedByMe,
          );
        })
        .toList(growable: false);
  }

  Future<bool> discardDraft(String draftId, {int? expectedVersion}) async {
    if (isClosed) return false;
    if (_discardingDraftId != null) return false;

    final current = state;
    if (current is! SalesDraftListLoaded) return false;

    SalesDraftListItemVm? row;
    for (final item in current.items) {
      if (item.draftId == draftId) {
        row = item;
        break;
      }
    }
    if (row == null) return false;

    final version = expectedVersion ?? row.version;
    _discardingDraftId = draftId;
    emit(
      current.copyWith(
        discardingDraftId: draftId,
        clearActionMessage: true,
        needsReload: false,
      ),
    );

    try {
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed) return false;

      await _repository.cancel(
        draftId: draftId,
        storeId: storeId,
        expectedVersion: version,
        idempotencyKey: 'cancel:$draftId:v$version',
      );
      if (isClosed) return false;

      final updated = current.items.where((item) => item.draftId != draftId).toList(growable: false);
      _discardingDraftId = null;
      emit(
        current.copyWith(
          items: updated,
          clearDiscarding: true,
          needsReload: false,
          clearActionMessage: true,
          totalCount: (current.totalCount - 1).clamp(0, 1 << 30),
        ),
      );
      return true;
    } on AppException catch (error) {
      if (isClosed) return false;
      _discardingDraftId = null;
      final stale = error.code == SalesDraftErrorCodes.staleData ||
                    error.code == 'STALE_VERSION' ||
                    error.code == SalesDraftErrorCodes.referenceUnavailable;
      emit(
        current.copyWith(
          clearDiscarding: true,
          needsReload: stale,
          actionMessage: stale
              ? 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'
              : salesDraftErrorMessage(error, fallback: 'Không xóa được đơn nháp'),
        ),
      );
      return false;
    } catch (_) {
      if (isClosed) return false;
      _discardingDraftId = null;
      emit(
        current.copyWith(
          clearDiscarding: true,
          needsReload: false,
          actionMessage: 'Không xóa được đơn nháp',
        ),
      );
      return false;
    }
  }
}
