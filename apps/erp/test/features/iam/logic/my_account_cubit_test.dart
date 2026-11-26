import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/iam/logic/my_account_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/session/fake_session_repository.dart';
import '../support/scripted_iam_repositories.dart';

final class _TwoTenantSessionRepository extends FakeSessionRepository {
  @override
  Future<List<AccessibleTenant>> listAccessibleTenants({String? currentTenantId}) async {
    return [
      AccessibleTenant(
        id: 'A',
        name: 'Tổ chức A',
        code: 'TEN-A',
        roleCode: 'store_owner',
        isOwner: true,
        isCurrent: currentTenantId == 'A',
      ),
      AccessibleTenant(
        id: 'B',
        name: 'Tổ chức B',
        code: 'TEN-B',
        roleCode: 'staff',
        isOwner: false,
        isCurrent: currentTenantId == 'B',
      ),
    ];
  }
}

SessionController _sessionFor({
  required String tenantId,
  required bool isOwner,
}) {
  final store = SessionStore();
  if (tenantId.isNotEmpty) {
    store.apply(
      SessionPrincipal(
        userId: 'u1',
        tenantId: tenantId,
        role: isOwner ? 'store_owner' : 'staff',
        isOwner: isOwner,
        permissions: const [],
      ),
    );
  } else {
    store.applyAuthenticatedUser('u1');
  }
  return SessionController(
    repository: _TwoTenantSessionRepository(),
    store: store,
    initialState: const SessionState(
      authStatus: AuthStatus.signedIn,
      userId: 'u1',
    ),
  );
}

void main() {
  test('owner badge follows the current tenant', () async {
    final accountRepo = ScriptedAccountRepository();
    final sessionB = _sessionFor(tenantId: 'B', isOwner: false);
    addTearDown(sessionB.close);
    final cubitB = MyAccountCubit(
      accountRepository: accountRepo,
      session: sessionB,
    );
    addTearDown(cubitB.close);

    await cubitB.load();
    expect(cubitB.state.isOwner, isFalse);

    final sessionA = _sessionFor(tenantId: 'A', isOwner: true);
    addTearDown(sessionA.close);
    final cubitA = MyAccountCubit(
      accountRepository: accountRepo,
      session: sessionA,
    );
    addTearDown(cubitA.close);

    await cubitA.load();
    expect(cubitA.state.isOwner, isTrue);
  });

  test('no current tenant falls back to any owned tenant', () async {
    final accountRepo = ScriptedAccountRepository();
    final session = _sessionFor(tenantId: '', isOwner: false);
    addTearDown(session.close);
    final cubit = MyAccountCubit(
      accountRepository: accountRepo,
      session: session,
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.isOwner, isTrue);
  });
}
