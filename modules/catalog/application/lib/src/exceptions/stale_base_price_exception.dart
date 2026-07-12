import 'package:vet45_shared_application/application.dart';

final class StaleBasePriceException extends ApplicationException {
  StaleBasePriceException([String? message])
    : super(
        message ?? 'Base price changed since the suggestion was generated. Reload the suggestion.',
      );
}
