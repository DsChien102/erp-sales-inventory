import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ManualRuleMustHaveActorRule implements IBusinessRule {
  const ManualRuleMustHaveActorRule(this.actorId);

  final String actorId;

  @override
  bool isBroken() => actorId.trim().isEmpty;

  @override
  String get message => 'Manual customer price rule requires an actor.';
}
