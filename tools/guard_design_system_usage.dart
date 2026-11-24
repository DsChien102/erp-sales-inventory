import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final root = Directory.current.path;
  final erpFeaturesDir = Directory(p.join(root, 'apps', 'erp', 'lib', 'features'));

  final legacyMode = Platform.environment['GUARD_DESIGN_SYSTEM_LEGACY'] == '1';
  final strictMode = Platform.environment['GUARD_DESIGN_SYSTEM_STRICT'] == '1';

  int warnCount = 0;
  bool failed = false;

  void reportError(String msg) {
    if (legacyMode) {
      print('WARN: $msg');
      warnCount++;
    } else {
      print('ERROR: $msg');
      failed = true;
    }
  }

  void reportWarn(String msg) {
    if (strictMode) {
      reportError(msg);
    } else {
      print('WARN: $msg');
      warnCount++;
    }
  }

  void emit(String tier, String msg) {
    if (tier == 'enforced') {
      reportError(msg);
    } else {
      reportWarn(msg);
    }
  }

  // Determine file tier: enforced | monitored | skip
  String fileTier(String filePath) {
    final relPath = p.relative(filePath, from: root);

    // Read content to check bypass comment
    try {
      final content = File(filePath).readAsStringSync();
      if (content.contains('harness:allow-design-system-bypass')) {
        return 'skip';
      }
    } catch (_) {
      return 'skip';
    }

    // Skip non-UI patterns under presentation
    final skipPatterns = [
      '/bloc/',
      '_cubit.dart',
      '_state.dart',
      '_formatters.dart',
      '/mappers/',
      '/models/',
      '/services/',
      '/data/',
    ];
    for (final pattern in skipPatterns) {
      if (relPath.contains(pattern)) {
        return 'skip';
      }
    }

    // --- ENFORCED (golden lane) ---
    final enforcedFiles = [
      'apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart',
      'apps/erp/lib/features/catalog/presentation/pages/product_catalog_tab_page.dart',
      'apps/erp/lib/features/catalog/presentation/widgets/product_list_filter.dart',
    ];

    if (enforcedFiles.contains(relPath)) {
      return 'enforced';
    }

    if (relPath.startsWith('apps/erp/lib/features/catalog/presentation/widgets/product_control_center_') ||
        relPath.startsWith('apps/erp/lib/features/catalog/presentation/widgets/product_catalog_')) {
      return 'enforced';
    }

    // --- MONITORED (scan / warn) ---
    if (relPath.startsWith('apps/erp/lib/features/') && relPath.contains('/presentation/')) {
      return 'monitored';
    }

    return 'skip';
  }

  final edgeInsetsRegex = RegExp(r'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]');
  final overlayRegex = RegExp(r'\b(AlertDialog|showModalBottomSheet|ElevatedButton)\s*\(');
  final textRegex = RegExp(r'\bText\s*\(');
  final scaffoldRegex = RegExp(r'\bScaffold\s*\(');
  final colorsRegex = RegExp(r'\bColors\.(grey|black|white|red|blue|green|yellow|orange|purple|pink|teal)\b');
  final sizeBoxRegex = RegExp(r'\bSizedBox\s*\(\s*(height|width)\s*:\s*[0-9]');

  // Exclusions for raw Text matching
  final textExclusions = RegExp(
    r'TextSpan|TextStyle|TextButton|TextField|TextEditingController|TextAlign|TextOverflow|TextDirection|TextPainter|TextInput|TextTheme|TextScaler',
  );

  void checkFile(File file) {
    final path = file.path;
    if (path.endsWith('.g.dart') || path.contains('/test/')) return;

    final tier = fileTier(path);
    if (tier == 'skip') return;

    final lines = file.readAsLinesSync();
    final relPath = p.relative(path, from: root);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // 1. Magic Spacing
      if (edgeInsetsRegex.hasMatch(line)) {
        emit(tier, 'magic EdgeInsets literal (use VSpacing/VGap/VPagePadding) at $relPath:$lineNum');
        print('  > $line');
      }

      // 2. Raw Overlays
      if (overlayRegex.hasMatch(line)) {
        emit(tier, 'raw overlay/button component at $relPath:$lineNum');
        print('  > $line');
      }

      // 3. Raw Text
      if (textRegex.hasMatch(line) && !textExclusions.hasMatch(line)) {
        emit(tier, 'raw Text widget (use VText) at $relPath:$lineNum');
        print('  > $line');
      }

      // 4. Raw Scaffold
      if (scaffoldRegex.hasMatch(line)) {
        final isPage = path.endsWith('_page.dart') || path.endsWith('_screen.dart');
        if (isPage && !lines.any((l) => l.contains('VPageScaffold'))) {
          emit(tier, 'raw Scaffold (prefer VPageScaffold for pages) at $relPath:$lineNum');
          print('  > $line');
        }
      }

      // 5. Raw Colors
      if (colorsRegex.hasMatch(line)) {
        emit(tier, 'raw Material color (use context.vColors/VColors semantic) at $relPath:$lineNum');
        print('  > $line');
      }

      // 6. Raw SizedBox (Vertical/Horizontal gap)
      if (sizeBoxRegex.hasMatch(line)) {
        emit(tier, 'raw SizedBox with literal sizes (use VGap) at $relPath:$lineNum');
        print('  > $line');
      }
    }
  }

  void scanDir(Directory dir) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        checkFile(entity);
      }
    }
  }

  print('Running Design System Usage Guard (Dart Version)...');
  scanDir(erpFeaturesDir);

  print('');
  print('Summary: enforced lane = product_control_center* + product_catalog*');
  print('         monitored = apps/erp features presentation');
  if (warnCount > 0) {
    print('WARN count: $warnCount (set GUARD_DESIGN_SYSTEM_STRICT=1 to fail on monitored)');
  }

  if (failed) {
    print('Design System Guard FAILED on enforced files.');
    exit(1);
  } else {
    print('OK: design system usage guard passed (enforced lane clean)');
  }
}
