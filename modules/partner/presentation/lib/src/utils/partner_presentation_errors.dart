import 'package:vet45_shared_application/application.dart';

String partnerErrorMessage(Object error) {
  if (error is ApplicationException) {
    return error.message;
  }
  return error.toString();
}
