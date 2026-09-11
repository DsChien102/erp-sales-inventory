import 'package:vet45_shared_application/application.dart';

/// Application-layer failure with a stable blocked code for UI mapping.
final class IamBlockedException extends ApplicationException {
  const IamBlockedException(this.code, {String? message, this.details})
    : super(message ?? code);

  final String code;
  final Map<String, Object?>? details;

  @override
  String toString() => message ?? code;
}
