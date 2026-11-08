import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _FakeFunctions implements FunctionsClient {
  final List<(String, dynamic)> recordedCalls = [];
  Future<FunctionResponse> Function(String functionName, dynamic body)? onInvoke;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #invoke) {
      final functionName = invocation.positionalArguments[0] as String;
      final body = invocation.namedArguments[#body];
      recordedCalls.add((functionName, body));
      if (onInvoke != null) {
        return onInvoke!(functionName, body);
      }
      return Future.value(FunctionResponse(status: 200, data: null));
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  const tenant = '11111111-1111-4111-8111-111111111111';

  test('kick_invokes_processor_with_tenant: kick(tenant) invokes einvoice-processor once with tenant_id', () async {
    final functions = _FakeFunctions();
    final trigger = EInvoiceProcessorTrigger(functions);

    trigger.kick(tenant);
    await pumpEventQueue();

    expect(functions.recordedCalls.length, 1);
    expect(functions.recordedCalls.first.$1, 'einvoice-processor');
    expect(functions.recordedCalls.first.$2, {'tenant_id': tenant});
  });

  test('kick_failure_does_not_throw: async error from invoke does not propagate', () async {
    final functions = _FakeFunctions()
      ..onInvoke = (name, body) => Future.error(FunctionException(status: 500));
    final trigger = EInvoiceProcessorTrigger(functions);

    expect(() => trigger.kick(tenant), returnsNormally);
    await pumpEventQueue();
  });

  test('kick_sync_throw_does_not_throw: synchronous throw in invoke does not propagate', () async {
    final functions = _FakeFunctions()
      ..onInvoke = (name, body) => throw StateError('sync failure');
    final trigger = EInvoiceProcessorTrigger(functions);

    expect(() => trigger.kick(tenant), returnsNormally);
    await pumpEventQueue();
  });
}
