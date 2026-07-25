import 'package:vet45_shared_application/application.dart';

final class PriceBandOverwriteRequiredException extends ApplicationException {
  PriceBandOverwriteRequiredException({
    this.existingListAfterVat,
    this.existingFloorAfterVat,
    String? message,
  }) : super(
         message ??
             'Product already has a price band. Confirm overwrite to apply Store Price Rule.',
       );

  final int? existingListAfterVat;
  final int? existingFloorAfterVat;
}
