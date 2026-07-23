/// Splits a command-line style string into argv tokens.
///
/// Supports single- and double-quoted segments; does not expand escapes.
List<String> parseCliArgs(String input) {
  final result = <String>[];
  final buf = StringBuffer();
  String? quote;

  void flush() {
    if (buf.isEmpty) {
      return;
    }
    result.add(buf.toString());
    buf.clear();
  }

  for (final rune in input.runes) {
    final c = String.fromCharCode(rune);
    if (quote != null) {
      if (c == quote) {
        quote = null;
      } else {
        buf.write(c);
      }
      continue;
    }
    if (c == '"' || c == "'") {
      quote = c;
      continue;
    }
    if (c == ' ' || c == '\t' || c == '\n') {
      flush();
      continue;
    }
    buf.write(c);
  }
  flush();
  return result;
}
