import 'package:equatable/equatable.dart';
import 'package:vet45_pricing_application/application.dart';

sealed class PriceRuleHistoryState extends Equatable {
  const PriceRuleHistoryState({
    required this.items,
    required this.nextCursor,
    required this.hasReachedMax,
    this.ruleContext,
    this.hasPermission = true,
    this.hasSensitivePermission = true,
  });

  final List<CustomerPriceRuleActivityDto> items;
  final String? nextCursor;
  final bool hasReachedMax;
  final CustomerPriceRuleDetailDto? ruleContext;
  final bool hasPermission;
  final bool hasSensitivePermission;

  @override
  List<Object?> get props => [
        items,
        nextCursor,
        hasReachedMax,
        ruleContext?.id,
        hasPermission,
        hasSensitivePermission,
      ];
}

final class PriceRuleHistoryInitial extends PriceRuleHistoryState {
  const PriceRuleHistoryInitial()
      : super(items: const [], nextCursor: null, hasReachedMax: false);
}

final class PriceRuleHistoryLoading extends PriceRuleHistoryState {
  const PriceRuleHistoryLoading({
    required super.items,
    required super.nextCursor,
    required super.hasReachedMax,
    super.ruleContext,
    super.hasPermission,
    super.hasSensitivePermission,
    this.isFirstLoad = false,
  });

  final bool isFirstLoad;

  @override
  List<Object?> get props => [...super.props, isFirstLoad];
}

final class PriceRuleHistoryLoaded extends PriceRuleHistoryState {
  const PriceRuleHistoryLoaded({
    required super.items,
    required super.nextCursor,
    required super.hasReachedMax,
    super.ruleContext,
    super.hasPermission,
    super.hasSensitivePermission,
  });
}

final class PriceRuleHistoryNoPermission extends PriceRuleHistoryState {
  const PriceRuleHistoryNoPermission({
    super.ruleContext,
  }) : super(
          items: const [],
          nextCursor: null,
          hasReachedMax: true,
          hasPermission: false,
        );
}

final class PriceRuleHistoryError extends PriceRuleHistoryState {
  const PriceRuleHistoryError({
    required super.items,
    required super.nextCursor,
    required super.hasReachedMax,
    required this.message,
    super.ruleContext,
    super.hasPermission,
    super.hasSensitivePermission,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
