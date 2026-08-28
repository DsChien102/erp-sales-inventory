enum PublishPreparationAction { callProvider, reconcileOnly, skip }

final class PublishPreparationDto {
  const PublishPreparationDto({required this.action});

  final PublishPreparationAction action;
}
