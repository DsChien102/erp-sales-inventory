import 'package:vet45_shared_application/application.dart';

final class StorePriceRuleNotFoundException extends ApplicationException {
  StorePriceRuleNotFoundException([String? message])
      : super(message ?? 'Store Price Rule not found.');
}
