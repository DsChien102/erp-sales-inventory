import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase/supabase.dart';

class EInvoiceProcessorTrigger {
  EInvoiceProcessorTrigger(FunctionsClient functions) : _functions = functions;

  final FunctionsClient _functions;
  static final _log = Logger('EInvoiceProcessorTrigger');

  /// Không chờ, không ném. Lỗi → Logger('EInvoiceProcessorTrigger').warning(...) (không ghi body / tenant).
  void kick(String tenantId) {
    try {
      unawaited(
        _functions
            .invoke('einvoice-processor', body: {'tenant_id': tenantId})
            .then(
              (_) {},
              onError: (Object e, StackTrace st) =>
                  _log.warning('einvoice-processor kick failed', e, st),
            ),
      );
    } catch (e, st) {
      _log.warning('einvoice-processor kick failed synchronously', e, st);
    }
  }
}

