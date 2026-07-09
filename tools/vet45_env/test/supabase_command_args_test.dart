import 'package:test/test.dart';
import 'package:vet45_env/supabase_command_args.dart';

void main() {
  test('parses profile flag and leaves supabase subcommands intact', () {
    final parsed = SupabaseCommandArgs.parse(
      ['--profile', 'default', 'projects', 'list'],
      defaultEnvironmentId: 'development',
    );

    expect(parsed.profileId, 'default');
    expect(parsed.environmentId, 'development');
    expect(parsed.supabaseArgs, ['projects', 'list']);
  });

  test('parses explicit --env without consuming supabase args', () {
    final parsed = SupabaseCommandArgs.parse(
      ['--profile', 'acme', '--env', 'staging', 'db', 'push'],
      defaultEnvironmentId: 'development',
    );

    expect(parsed.profileId, 'acme');
    expect(parsed.environmentId, 'staging');
    expect(parsed.supabaseArgs, ['db', 'push']);
  });

  test('does not treat project as environment id', () {
    final parsed = SupabaseCommandArgs.parse(
      ['--profile', 'default', 'project', 'list'],
      defaultEnvironmentId: 'staging',
    );

    expect(parsed.environmentId, 'staging');
    expect(parsed.supabaseArgs, ['project', 'list']);
  });
}
