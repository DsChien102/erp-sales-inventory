import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';

enum StocktakeResultLoadStatus { loading, error, ready }

class StocktakeResultState extends Equatable {
  const StocktakeResultState({
    this.status = StocktakeResultLoadStatus.loading,
    this.session,
  });

  final StocktakeResultLoadStatus status;
  final StocktakeSession? session;

  @override
  List<Object?> get props => [status, session];
}

