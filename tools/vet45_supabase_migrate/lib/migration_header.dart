import 'sql_function_extractor.dart';

const migrationKinds = {'bootstrap', 'patch', 'surgical'};

class MigrationHeader {
  const MigrationHeader({
    this.title,
    this.kind,
    this.intent,
    this.context,
    this.touches = const [],
    this.safety,
    this.dependsOn = const [],
    this.promotedFrom = const [],
  });

  final String? title;
  final String? kind;
  final String? intent;
  final String? context;
  final List<String> touches;
  final String? safety;
  final List<String> dependsOn;
  final List<String> promotedFrom;

  bool get hasKind => kind != null && kind!.isNotEmpty;

  static MigrationHeader parse(String sql) {
    final lines = sql.split('\n');
    String? title;
    String? kind;
    String? intent;
    String? context;
    String? safety;
    final touches = <String>[];
    final dependsOn = <String>[];
    final promotedFrom = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('--')) {
        if (trimmed.isNotEmpty) {
          break;
        }
        continue;
      }

      final content = trimmed.substring(2).trim();
      if (content.startsWith('Title:')) {
        title = content.substring('Title:'.length).trim();
      } else if (content.startsWith('Kind:')) {
        kind = content.substring('Kind:'.length).trim().toLowerCase();
      } else if (content.startsWith('Intent:')) {
        intent = content.substring('Intent:'.length).trim();
      } else if (content.startsWith('Context:')) {
        context = content.substring('Context:'.length).trim();
      } else if (content.startsWith('Touches:')) {
        touches.addAll(_splitCsv(content.substring('Touches:'.length)));
      } else if (content.startsWith('Safety:')) {
        safety = content.substring('Safety:'.length).trim();
      } else if (content.startsWith('Depends on:')) {
        dependsOn.addAll(_splitCsv(content.substring('Depends on:'.length)));
      } else if (content.startsWith('Promoted from _drafts/')) {
        promotedFrom.add(content.substring('Promoted from _drafts/'.length).trim());
      }
    }

    return MigrationHeader(
      title: title,
      kind: kind,
      intent: intent,
      context: context,
      touches: touches,
      safety: safety,
      dependsOn: dependsOn,
      promotedFrom: promotedFrom,
    );
  }

  String toCommentBlock({List<String>? extraPromotedFrom}) {
    final buffer = StringBuffer();
    if (title != null && title!.isNotEmpty) {
      buffer.writeln('-- Title: $title');
    }
    if (kind != null && kind!.isNotEmpty) {
      buffer.writeln('-- Kind: $kind');
    }
    if (intent != null && intent!.isNotEmpty) {
      buffer.writeln('-- Intent: $intent');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.writeln('-- Context: $context');
    }
    if (touches.isNotEmpty) {
      buffer.writeln('-- Touches: ${touches.join(', ')}');
    }
    if (safety != null && safety!.isNotEmpty) {
      buffer.writeln('-- Safety: $safety');
    }
    if (dependsOn.isNotEmpty) {
      buffer.writeln('-- Depends on: ${dependsOn.join(', ')}');
    }
    for (final source in {...promotedFrom, ...?extraPromotedFrom}) {
      buffer.writeln('-- Promoted from _drafts/$source');
    }
    return buffer.toString().trimRight();
  }

  MigrationHeader merge(MigrationHeader other) {
    return MigrationHeader(
      title: title ?? other.title,
      kind: kind ?? other.kind,
      intent: intent ?? other.intent,
      context: context ?? other.context,
      touches: {...touches, ...other.touches}.toList()..sort(),
      safety: safety ?? other.safety,
      dependsOn: {...dependsOn, ...other.dependsOn}.toList(),
      promotedFrom: {...promotedFrom, ...other.promotedFrom}.toList(),
    );
  }

  static MigrationHeader withTouchesFromBody({
    required MigrationHeader base,
    required String sqlBody,
  }) {
    if (base.touches.isNotEmpty) {
      return base;
    }
    return MigrationHeader(
      title: base.title,
      kind: base.kind,
      intent: base.intent,
      context: base.context,
      touches: extractFunctionNamesFromSql(sqlBody),
      safety: base.safety,
      dependsOn: base.dependsOn,
      promotedFrom: base.promotedFrom,
    );
  }

  static List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

String stripHeaderComments(String sql) {
  final lines = sql.split('\n');
  final body = <String>[];
  var inHeader = true;

  for (final line in lines) {
    final trimmed = line.trim();
    if (inHeader) {
      if (trimmed.isEmpty || trimmed.startsWith('--')) {
        continue;
      }
      inHeader = false;
    }
    body.add(line);
  }

  return body.join('\n').trim();
}
