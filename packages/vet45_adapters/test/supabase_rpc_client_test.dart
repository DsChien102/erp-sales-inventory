import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  test('SupabaseRpcClient implements IRpcClient', () {
    expect(_assertRpcClient<SupabaseRpcClient>(), isTrue);
  });
}

bool _assertRpcClient<T extends IRpcClient>() => true;
