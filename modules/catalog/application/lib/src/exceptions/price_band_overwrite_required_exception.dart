import 'package:vet45_shared_application/application.dart';

final class PriceBandOverwriteRequiredException extends ApplicationException {
  PriceBandOverwriteRequiredException({
    this.existingListBeforeVat,
    this.existingFloorBeforeVat,
    String? message,
  }) : super(
         message ??
             'Product already has a price band. Confirm overwrite to apply Store Price Rule.',
       );

  final int? existingListBeforeVat;
  final int? existingFloorBeforeVat;
}
