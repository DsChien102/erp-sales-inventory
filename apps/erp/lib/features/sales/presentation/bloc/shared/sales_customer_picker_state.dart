import 'package:equatable/equatable.dart';

import '../../models/shared/sales_customer_selection.dart';

sealed class SalesCustomerPickerState extends Equatable {
  const SalesCustomerPickerState({
    required this.query,
    required this.items,
  });

  final String query;
  final List<SalesCustomerListItemVm> items;

  @override
  List<Object?> get props => [query, items];
}

/// Đang tải danh sách / tìm kiếm — body hiển thị skeleton.
final class SalesCustomerPickerLoading extends SalesCustomerPickerState {
  const SalesCustomerPickerLoading({super.query = ''}) : super(items: const []);
}

final class SalesCustomerPickerLoaded extends SalesCustomerPickerState {
  const SalesCustomerPickerLoaded({
    required super.query,
    required super.items,
  });
}

final class SalesCustomerPickerEmpty extends SalesCustomerPickerState {
  const SalesCustomerPickerEmpty() : super(query: '', items: const []);
}

final class SalesCustomerPickerNoResult extends SalesCustomerPickerState {
  const SalesCustomerPickerNoResult({required super.query}) : super(items: const []);
}

/// Lỗi tải / tìm kiếm — hiển thị trong body (không floating banner).
final class SalesCustomerPickerError extends SalesCustomerPickerState {
  const SalesCustomerPickerError({
    required super.query,
    required this.title,
    required this.description,
  }) : super(items: const []);

  final String title;
  final String description;

  @override
  List<Object?> get props => [...super.props, title, description];
}
