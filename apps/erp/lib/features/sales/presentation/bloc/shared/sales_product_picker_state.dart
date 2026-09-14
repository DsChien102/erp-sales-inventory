import 'package:equatable/equatable.dart';

import '../../models/shared/sales_sellable_product_vm.dart';

sealed class SalesProductPickerState extends Equatable {
  const SalesProductPickerState({
    required this.query,
    required this.items,
  });

  final String query;
  final List<SalesSellableProductVm> items;

  @override
  List<Object?> get props => [query, items];
}

final class SalesProductPickerLoading extends SalesProductPickerState {
  const SalesProductPickerLoading({required super.query}) : super(items: const []);
}

final class SalesProductPickerLoaded extends SalesProductPickerState {
  const SalesProductPickerLoaded({
    required super.query,
    required super.items,
  });
}

final class SalesProductPickerEmptyCatalog extends SalesProductPickerState {
  const SalesProductPickerEmptyCatalog() : super(query: '', items: const []);
}

final class SalesProductPickerNoResult extends SalesProductPickerState {
  const SalesProductPickerNoResult({required super.query}) : super(items: const []);
}

final class SalesProductPickerError extends SalesProductPickerState {
  const SalesProductPickerError({required super.query, required this.message})
    : super(items: const []);

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
