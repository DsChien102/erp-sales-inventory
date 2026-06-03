import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

/// Matches [ValidationException] with an optional message substring.
Matcher throwsCommandValidation([String? messageContains]) {
  return throwsA(
    predicate<ValidationException>((error) {
      if (messageContains == null) {
        return true;
      }
      return error.message.contains(messageContains);
    }, 'is ValidationException'),
  );
}
