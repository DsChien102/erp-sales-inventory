import 'package:equatable/equatable.dart';
import '../../data/hub/warehouse_hub_summary.dart';

sealed class WarehouseHubState extends Equatable {
  const WarehouseHubState();

  @override
  List<Object?> get props => [];
}

final class WarehouseHubLoading extends WarehouseHubState {
  const WarehouseHubLoading();
}

final class WarehouseHubLoaded extends WarehouseHubState {
  const WarehouseHubLoaded({
    required this.summary,
    required this.isOwner,
  });

  final WarehouseHubSummary summary;
  final bool isOwner;

  @override
  List<Object?> get props => [summary, isOwner];
}

final class WarehouseHubError extends WarehouseHubState {
  const WarehouseHubError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
