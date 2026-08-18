import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../effective_issuance_configuration.dart';

/// Template and signing must form a compatible combo before save.
final class TemplateSigningMustBeCompatibleRule implements IBusinessRule {
  const TemplateSigningMustBeCompatibleRule({required this.configuration});

  final EffectiveIssuanceConfiguration configuration;

  @override
  bool isBroken() => !configuration.isCompatible();

  @override
  String get message =>
      'Selected template and signing configuration are not compatible';
}
