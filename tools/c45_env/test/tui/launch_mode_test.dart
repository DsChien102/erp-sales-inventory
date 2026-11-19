import 'package:test/test.dart';
import 'package:c45_env/tui/launch_mode.dart';

void main() {
  test('empty args launches TUI', () {
    expect(parseLaunchMode([]), LaunchMode.tui);
  });

  test('tui command launches TUI', () {
    expect(parseLaunchMode(['tui']), LaunchMode.tui);
  });

  test('help flags', () {
    expect(parseLaunchMode(['--help']), LaunchMode.help);
    expect(parseLaunchMode(['-h']), LaunchMode.help);
  });

  test('other commands stay CLI', () {
    expect(parseLaunchMode(['list']), LaunchMode.cli);
    expect(parseLaunchMode(['switch', 'acme']), LaunchMode.cli);
  });
}
