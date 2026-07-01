import 'package:vet45_shared_application/application.dart';

String partnerErrorMessage(Object error) {
  if (error is ApplicationException) {
    final msg = error.message;
    if (msg.contains('Permission denied')) {
      return 'Bạn không có quyền phù hợp.';
    }
    return msg;
  }
  final errStr = error.toString();
  if (errStr.contains('Permission denied')) {
    return 'Bạn không có quyền phù hợp.';
  }
  return errStr;
}

