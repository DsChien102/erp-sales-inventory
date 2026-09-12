import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/shared/sales_customer_selection.dart';
import '../../support/sales_external_lookups.dart';
import 'sales_customer_picker_state.dart';

final class SalesCustomerPickerCubit extends Cubit<SalesCustomerPickerState> {
  SalesCustomerPickerCubit({required SalesCustomerSearchFn searchCustomers})
    : _searchCustomers = searchCustomers,
      super(const SalesCustomerPickerLoading());

  final SalesCustomerSearchFn _searchCustomers;

  Future<void> loadInitial() => search('');

  Future<void> search(String query) async {
    final trimmed = query.trim();
    emit(SalesCustomerPickerLoading(query: trimmed));
    try {
      final items = await _searchCustomers(trimmed);
      _emitFor(trimmed, items);
    } catch (_) {
      emit(
        SalesCustomerPickerError(
          query: trimmed,
          title: trimmed.isEmpty ? 'Không thể tải khách hàng' : 'Không thể tìm kiếm',
          description: 'Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  void clearSearch() {
    search('');
  }

  void _emitFor(String query, List<SalesCustomerListItemVm> items) {
    if (items.isEmpty && query.isEmpty) {
      emit(const SalesCustomerPickerEmpty());
      return;
    }
    if (items.isEmpty) {
      emit(SalesCustomerPickerNoResult(query: query));
      return;
    }
    emit(SalesCustomerPickerLoaded(query: query, items: items));
  }
}
