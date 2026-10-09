import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:erp/features/auth/data/models/signup_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';

class _Rpc extends SupabaseRpc {
  _Rpc()
    : super(
        SupabaseClient(
          'http://127.0.0.1',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
}

class _Auth extends Mock implements GoTrueClient {}

class _User extends Mock implements User {}

void main() {
  const account = SignupAccountInput(
    givenName: 'Lan',
    familyName: 'Nguyen',
    email: 'Lan@Example.com',
    password: 'password-1',
    confirmPassword: 'password-1',
    phone: '0912345678',
  );
  const store = SignupStoreInput(
    name: 'Thú y An Phát',
    contactPhone: '0912000111',
    provinceCode: '01',
    communeCode: '00001',
    addressText: '12 Nguyen Trai',
  );

  late _Auth auth;
  late _User user;

  setUp(() {
    auth = _Auth();
    user = _User();
    when(() => user.id).thenReturn('user-1');
    when(() => user.email).thenReturn('lan@example.com');
  });

  test('signUpStore sends profile and signup_tenant metadata', () async {
    Map<String, dynamic>? data;
    when(() => user.identities).thenReturn(null);
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((invocation) async {
      data = invocation.namedArguments[#data] as Map<String, dynamic>?;
      return AuthResponse(user: user);
    });
    final repository = AuthRepository(rpc: _Rpc(), auth: auth);

    await repository.signUpStore(account: account, store: store);

    expect(data?['profile'], {
      'given_name': 'Lan',
      'family_name': 'Nguyen',
      'phone': '0912345678',
    });
    expect(data?['signup_tenant'], {
      'name': 'Thú y An Phát',
      'contact_phone': '0912000111',
      'contact_email': 'lan@example.com',
      'province_code': '01',
      'commune_code': '00001',
      'address_text': '12 Nguyen Trai',
    });
  });

  test('empty identities means the email is already registered', () async {
    when(() => user.identities).thenReturn(const []);
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse(user: user));
    final repository = AuthRepository(rpc: _Rpc(), auth: auth);

    await expectLater(
      repository.signUpStore(account: account, store: store),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'PLATFORM_USER_ALREADY_EXISTS',
        ),
      ),
    );
  });
}
