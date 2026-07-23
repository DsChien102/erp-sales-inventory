import 'package:test/test.dart';
import 'package:vet45_env/tui/parse_cli_args.dart';

void main() {
  test('parseCliArgs splits on whitespace', () {
    expect(parseCliArgs('  --foo  bar  '), ['--foo', 'bar']);
  });

  test('parseCliArgs keeps quoted segments', () {
    expect(
      parseCliArgs(r'''--dart-define=A=1 -d "chrome beta" 'x y' '''),
      ['--dart-define=A=1', '-d', 'chrome beta', 'x y'],
    );
  });

  test('parseCliArgs empty', () {
    expect(parseCliArgs(''), isEmpty);
    expect(parseCliArgs('   '), isEmpty);
  });
}
