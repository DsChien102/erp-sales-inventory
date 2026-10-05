import 'dart:convert';

import 'package:supabase/supabase.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

Object mapInventoryTransportError(Object error, [StackTrace? stackTrace]) {
  if (error is PostgrestException) {
    return RpcException(error.message, cause: error);
  }
  return RpcException('Inventory RPC failed.', cause: error);
}

ApplicationException mapInventoryRpcError(RpcException error) {
  final message = error.message.trim();
  final code = _jsonCode(message);
  if (code != null) {
    return ApplicationException(code);
  }
  return ApplicationException(message);
}

String? _jsonCode(String message) {
  final start = message.indexOf('{');
  final end = message.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return null;
  }
  try {
    final decoded = jsonDecode(message.substring(start, end + 1));
    if (decoded is Map<String, dynamic>) {
      final code = decoded['code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
  } on FormatException {
    return null;
  }
  return null;
}
