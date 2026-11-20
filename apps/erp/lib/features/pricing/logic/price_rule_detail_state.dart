import 'package:equatable/equatable.dart';
import '../data/models.dart';

/// Trạng thái cubit chi tiết giá riêng (S3).
sealed class PriceRuleDetailState extends Equatable {
  const PriceRuleDetailState();

  @override
  List<Object?> get props => [];
}

final class PriceRuleDetailInitial extends PriceRuleDetailState {
  const PriceRuleDetailInitial();
}

final class PriceRuleDetailLoading extends PriceRuleDetailState {
  const PriceRuleDetailLoading();
}

final class PriceRuleDetailLoaded extends PriceRuleDetailState {
  const PriceRuleDetailLoaded({
    required this.rule,
    this.recentActivities = const [],
  });

  final CustomerPriceRuleDetailDto rule;
  final List<CustomerPriceRuleActivityDto> recentActivities;

  @override
  List<Object?> get props => [
        rule.id,
        rule.version,
        rule.persistedStatus,
        recentActivities.length,
      ];
}

final class PriceRuleDetailNotFound extends PriceRuleDetailState {
  const PriceRuleDetailNotFound();
}

final class PriceRuleDetailNoPermission extends PriceRuleDetailState {
  const PriceRuleDetailNoPermission();
}

final class PriceRuleDetailError extends PriceRuleDetailState {
  const PriceRuleDetailError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Sub-states sau khi thực hiện action (disable/reenable).
final class PriceRuleDetailActionSuccess extends PriceRuleDetailState {
  const PriceRuleDetailActionSuccess({
    required this.rule,
    this.recentActivities = const [],
  });

  final CustomerPriceRuleDetailDto rule;
  final List<CustomerPriceRuleActivityDto> recentActivities;

  @override
  List<Object?> get props => [rule.id, rule.version, recentActivities.length];
}
