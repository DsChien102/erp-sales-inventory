final class CustomerPriceRuleActivityActorDto {
  const CustomerPriceRuleActivityActorDto({
    required this.displayName,
    required this.isSystemActor,
    this.actorId,
  });

  final String? actorId;
  final String displayName;
  final bool isSystemActor;
}
