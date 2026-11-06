import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/logic/sales_draft_error_messages.dart';
import 'package:erp/features/sales/logic/sales_draft_list_state.dart';
import 'package:erp/features/sales/presentation/models/sales_order_draft/sales_draft_list_item_vm.dart';
import 'package:erp/features/sales/presentation/support/i_sales_active_store_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_application/application.dart';

typedef SalesActorNameResolver = Future<String?> Function(String actorId);

final class SalesDraftListCubit extends Cubit<SalesDraftListState> {
  SalesDraftListCubit({
    required SalesDraftRepository repository,
    required IExecutionContext executionContext,
    required ISalesActiveStoreContext activeStoreContext,
    SalesActorNameResolver? actorNameResolver,
  }) : _repository = repository,
       _executionContext = executionContext,
       _activeStoreContext = activeStoreContext,
       _actorNameResolver = actorNameResolver,
       super(const SalesDraftListInitial());

  final SalesDraftRepository _repository;
  final IExecutionContext _executionContext;
  final ISalesActiveStoreContext _activeStoreContext;
  final SalesActorNameResolver? _actorNameResolver;
  final Map<String, String> _actorNamesCache = {};

  List<SalesDraftListItemVm> _allRows = const <SalesDraftListItemVm>[];
  String? _query;
  String? _discardingDraftId;
  bool _isLoading = false;

  Future<void> load({bool isRefresh = false}) async {
    if (isClosed) return;
    if (_isLoading) return;
    _isLoading = true;
    try {
      await _load(isRefresh: isRefresh);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _load({required bool isRefresh}) async {
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
      ),
    );

    try {
      final actorId = await _executionContext.requireUserId();
      final storeId = await _activeStoreContext.requireActiveStoreId();
      if (isClosed) return;

      final result = await _repository.list(storeId: storeId, pageSize: 50);
      if (isClosed) return;

      final resolver = _actorNameResolver;
      if (resolver != null) {
        final uniqueActorIds = result.page.items
            .map((d) => d.savedByActorId.trim())
            .where((id) => id.isNotEmpty && !_actorNamesCache.containsKey(id))
            .toSet();
        for (final id in uniqueActorIds) {
          try {
            final resolved = await resolver(id);
            if (resolved != null && resolved.trim().isNotEmpty) {
              _actorNamesCache[id] = resolved.trim();
            }
          } catch (_) {}
        }
      }

      _allRows = _mapDrafts(
        result.page.items,
        currentUserId: actorId,
        actorNames: _actorNamesCache,
      );
      _emitFiltered(
        current,
        needsReload: false,
        clearActionMessage: true,
      );
    } on AppException catch (error) {
      if (isClosed) return;
      if (error.code == SalesDraftErrorCodes.noPermission ||
          error.code == SalesDraftErrorCodes.dataScopeDenied) {
        emit(
          SalesDraftListBlocked(
            message: salesDraftErrorMessage(error, fallback: 'Không thể tải danh sách đơn nháp'),
          ),
        );
        return;
      }
      emit(
        SalesDraftListError(
          'Không thể tải danh sách đơn nháp',
          query: _query,
          totalCount: current.totalCount,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        SalesDraftListError(
          'Không thể tải danh sách đơn nháp',
          query: _query,
          totalCount: current.totalCount,
        ),
      );
    }
  }

  List<SalesDraftListItemVm> _mapDrafts(
    List<SalesOrderDraftDto> items, {
    required String currentUserId,
    Map<String, String> actorNames = const {},
  }) {
    return items
        .map((d) {
          final customer = d.customer;
          final isOwnedByMe = d.savedByActorId == currentUserId;
          final resolvedName = actorNames[d.savedByActorId];
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
            createdByName: resolvedName ?? d.savedByActorId,
            isOwnedByMe: isOwnedByMe,
          );
        })
        .toList(growable: false);
  }

  Future<void> searchByKeyword(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    _emitFiltered(state);
  }

  void clearSearch() {
    searchByKeyword('');
  }

  Future<bool> discardDraft(String draftId, {int? expectedVersion}) async {
    if (isClosed) return false;
    if (_discardingDraftId != null) return false;

    SalesDraftListItemVm? row;
    for (final item in _allRows) {
      if (item.draftId == draftId) {
        row = item;
        break;
      }
    }
    if (row == null) return false;

    final version = expectedVersion ?? row.version;
    _discardingDraftId = draftId;
    _emitFiltered(
      state,
      discardingDraftId: draftId,
      clearActionMessage: true,
      needsReload: false,
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

      _allRows = _allRows.where((item) => item.draftId != draftId).toList(growable: false);
      _discardingDraftId = null;
      _emitFiltered(
        state,
        clearDiscarding: true,
        needsReload: false,
        clearActionMessage: true,
      );
      return true;
    } on AppException catch (error) {
      if (isClosed) return false;
      _discardingDraftId = null;
      final stale = error.code == SalesDraftErrorCodes.staleData || error.code == 'STALE_VERSION';
      _emitFiltered(
        state,
        clearDiscarding: true,
        needsReload: stale,
        actionMessage: stale
            ? 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'
            : salesDraftErrorMessage(error, fallback: 'Không hủy được đơn nháp'),
      );
      return false;
    } catch (_) {
      if (isClosed) return false;
      _discardingDraftId = null;
      _emitFiltered(
        state,
        clearDiscarding: true,
        needsReload: false,
        actionMessage: 'Không hủy được đơn nháp',
      );
      return false;
    }
  }

  void _emitFiltered(
    SalesDraftListState current, {
    String? discardingDraftId,
    bool clearDiscarding = false,
    bool? needsReload,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    var list = _allRows;

    final q = _query?.toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list
          .where((item) {
            final text = [
              item.customerLabel,
              item.phone ?? '',
              item.note ?? '',
              item.draftId,
            ].join(' ').toLowerCase();
            return text.contains(q);
          })
          .toList(growable: false);
    }

    final nextDiscarding = clearDiscarding ? null : (discardingDraftId ?? _discardingDraftId);
    final nextNeedsReload = needsReload ?? current.needsReload;
    final nextActionMessage = clearActionMessage ? null : (actionMessage ?? current.actionMessage);

    emit(
      SalesDraftListLoaded(
        items: list,
        isDefaultEmpty: _allRows.isEmpty,
        query: _query,
        isCreating: current.isCreating,
        discardingDraftId: nextDiscarding,
        needsReload: nextNeedsReload,
        actionMessage: nextActionMessage,
        totalCount: _allRows.length,
      ),
    );
  }
}
