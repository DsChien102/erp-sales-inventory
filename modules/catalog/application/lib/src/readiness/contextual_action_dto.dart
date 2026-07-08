import 'contextual_action_priority.dart';

final class ContextualActionDto {
  const ContextualActionDto({
    required this.actionId,
    required this.label,
    required this.priority,
    required this.enabled,
    this.requiredPermission,
    this.targetModule,
  });

  final String actionId;
  final String label;
  final ContextualActionPriority priority;
  final bool enabled;
  final String? requiredPermission;
  final String? targetModule;
}
