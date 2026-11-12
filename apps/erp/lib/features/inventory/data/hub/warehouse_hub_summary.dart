import 'package:equatable/equatable.dart';

class WarehouseAttention extends Equatable {
  const WarehouseAttention({
    required this.count,
    required this.text,
  });

  final int count;
  final String text;

  @override
  List<Object?> get props => [count, text];
}

class WarehouseHubSummary extends Equatable {
  const WarehouseHubSummary({
    required this.activated,
    this.problems,
    this.openStocktakes = 0,
  });

  final bool activated;
  final WarehouseAttention? problems;
  final int openStocktakes;

  @override
  List<Object?> get props => [activated, problems, openStocktakes];
}
