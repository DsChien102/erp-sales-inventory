import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ReturnQuantityCannotExceedReturnableRule implements IBusinessRule {
  const ReturnQuantityCannotExceedReturnableRule({
    required this.requestedMicros,
    required this.returnableMicros,
  });

  final int requestedMicros;
  final int returnableMicros;

  @override
  bool isBroken() => requestedMicros > returnableMicros;

  @override
  String get message => 'Return quantity cannot exceed remaining returnable quantity.';
}
