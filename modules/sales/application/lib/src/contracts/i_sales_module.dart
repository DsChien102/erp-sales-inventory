import 'package:vet45_shared_application/application.dart';

/// Public facade for the sales bounded context.
abstract interface class ISalesModule implements IModuleMediator {
  /// Frozen documentation/application contract version for TH-05.
  static const contractVersion = 'th05-v1';

  /// S01 is runtime-only; S02–S38 expose frozen application contracts.
  static const frozenContractSlices = 38;
}
