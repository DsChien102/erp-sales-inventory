import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  test('uses required customer search', () async {
    final cubit = SalesCustomerPickerCubit(
      searchCustomers: (query) async => [
        const SalesCustomerListItemVm(
          partnerId: 'partner-1',
          displayName: 'Nguyen Van A',
        ),
      ],
    );

    await cubit.search('Nguyen');

    final state = cubit.state as SalesCustomerPickerLoaded;
    expect(state.items.single.partnerId, 'partner-1');

    await cubit.close();
  });

  test('emits error state on backend failure', () async {
    final cubit = SalesCustomerPickerCubit(
      searchCustomers: (_) => Future.error(Exception('offline')),
    );

    await cubit.search('Nguyen');

    final state = cubit.state as SalesCustomerPickerError;
    expect(state.title, 'Không thể tìm kiếm');
    expect(state.description, 'Kiểm tra kết nối và thử lại.');
    expect(state.query, 'Nguyen');
    expect(state.items, isEmpty);

    await cubit.close();
  });

  test('emits load error when initial search fails', () async {
    final cubit = SalesCustomerPickerCubit(
      searchCustomers: (_) => Future.error(Exception('offline')),
    );

    await cubit.loadInitial();

    final state = cubit.state as SalesCustomerPickerError;
    expect(state.title, 'Không thể tải khách hàng');

    await cubit.close();
  });
}
