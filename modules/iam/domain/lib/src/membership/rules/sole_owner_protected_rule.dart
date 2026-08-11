import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Sole Owner must not be deactivated or removed.
final class SoleOwnerProtectedRule implements IBusinessRule {
  const SoleOwnerProtectedRule({
    required this.isOwner,
    required this.isSoleOwner,
  });

  final bool isOwner;
  final bool isSoleOwner;

  @override
  bool isBroken() => isOwner && isSoleOwner;

  @override
  String get message => 'Sole owner membership is protected';
}
