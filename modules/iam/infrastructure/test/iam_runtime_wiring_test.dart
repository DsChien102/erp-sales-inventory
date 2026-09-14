import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';

/// Offline client: the constructor performs no network I/O; IAM startup
/// does not restore persisted auth (host-owned).
SupabaseClient _offlineClient() =>
    SupabaseClient('https://offline.local', 'anon-test-key');

void main() {
  group('IAM runtime wiring (§S13/§S14 real adapters)', () {
    late GetIt container;

    setUp(() async {
      container = GetIt.asNewInstance();
      await IamStartup.initializeForTesting(
        supabase: _offlineClient(),
        container: container,
              );
    });

    tearDown(() => container.reset());

    test('registers the real Platform Identity self-service adapter', () {
      expect(
        container.get<IPlatformIdentitySelfServicePort>(),
        isA<SupabasePlatformIdentitySelfServiceAdapter>(),
      );
    });

    test('registers the public password-reset adapter', () {
      expect(
        container.get<IPasswordResetPublicPort>(),
        isA<SupabasePasswordResetPublicAdapter>(),
      );
    });

    test('registers the real tenant audit read adapter', () {
      expect(
        container.get<ITenantAuditReadPort>(),
        isA<SupabaseTenantAuditReadPort>(),
      );
    });

    test('keeps the existing Platform Admin gateway for S16 reads', () {
      expect(
        container.get<IPlatformAdminGateway>(),
        isA<SupabasePlatformAdminGateway>(),
      );
    });

    test('registers real S6-S9 invitation adapters', () {
      expect(
        container.get<ITenantInvitationReadPort>(),
        isA<SupabaseTenantInvitationReadPort>(),
      );
      expect(
        container.get<ITenantInvitationCommandGateway>(),
        isA<SupabaseTenantInvitationCommandGateway>(),
      );
      expect(
        container.get<ITenantInvitationAcceptancePort>(),
        isA<SupabaseTenantInvitationAcceptancePort>(),
      );
      expect(
        container.get<IInvitationIdentityPort>(),
        isA<SupabaseInvitationIdentityAdapter>(),
      );
    });
  });
}
