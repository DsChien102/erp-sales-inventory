import 'dart:io';

/// Resolved AOT binary path under `.c45/bin/`.
class AotBinary {
  AotBinary._(this.file);

  final File file;

  String get path => file.path;

  bool get exists => file.existsSync();

  static String fileName() => Platform.isWindows ? 'c45.exe' : 'c45';

  static Directory binDir(Directory repoRoot) =>
      Directory('${repoRoot.path}/.c45/bin');

  static File stampFile(Directory repoRoot) =>
      File('${repoRoot.path}/.c45/bin/c45.stamp');

  /// Legacy AOT name from before the `c45` rename — removed on rebuild.
  static File legacyFile(Directory repoRoot) => File(
        '${binDir(repoRoot).path}/${Platform.isWindows ? 'c45_env.exe' : 'c45_env'}',
      );

  static File legacyStampFile(Directory repoRoot) =>
      File('${repoRoot.path}/.c45/bin/c45_env.stamp');

  static AotBinary resolve(Directory repoRoot) =>
      AotBinary._(File('${binDir(repoRoot).path}/${fileName()}'));
}
