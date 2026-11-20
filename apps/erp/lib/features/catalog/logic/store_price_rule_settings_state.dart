import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

abstract class StorePriceRuleSettingsState extends Equatable {
  const StorePriceRuleSettingsState();

  @override
  List<Object?> get props => [];
}

class StorePriceRuleSettingsInitial extends StorePriceRuleSettingsState {}

class StorePriceRuleSettingsLoading extends StorePriceRuleSettingsState {}

class StorePriceRuleSettingsLoaded extends StorePriceRuleSettingsState {
  final StorePriceRuleDto? rule;

  const StorePriceRuleSettingsLoaded({this.rule});

  @override
  List<Object?> get props => [rule];
}

class StorePriceRuleSettingsSaving extends StorePriceRuleSettingsState {
  final StorePriceRuleDto? previousRule;

  const StorePriceRuleSettingsSaving({this.previousRule});

  @override
  List<Object?> get props => [previousRule];
}

class StorePriceRuleSettingsSaved extends StorePriceRuleSettingsState {
  final StorePriceRuleDto rule;

  const StorePriceRuleSettingsSaved({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class StorePriceRuleSettingsError extends StorePriceRuleSettingsState {
  final String message;
  final StorePriceRuleDto? previousRule;

  const StorePriceRuleSettingsError({
    required this.message,
    this.previousRule,
  });

  @override
  List<Object?> get props => [message, previousRule];
}
