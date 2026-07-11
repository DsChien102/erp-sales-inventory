import 'dart:io';

/// Resolved AOT binary path under `.vet45/bin/`.
class AotBinary {
  AotBinary._(this.file);

  final File file;

  String get path => file.path;

  bool get exists => file.existsSync();

  static String fileName() => Platform.isWindows ? 'vet45.exe' : 'vet45';

  static Directory binDir(Directory repoRoot) =>
      Directory('${repoRoot.path}/.vet45/bin');

  static File stampFile(Directory repoRoot) =>
      File('${repoRoot.path}/.vet45/bin/vet45.stamp');

  /// Legacy AOT name from before the `vet45` rename — removed on rebuild.
  static File legacyFile(Directory repoRoot) => File(
        '${binDir(repoRoot).path}/${Platform.isWindows ? 'vet45_env.exe' : 'vet45_env'}',
      );

  static File legacyStampFile(Directory repoRoot) =>
      File('${repoRoot.path}/.vet45/bin/vet45_env.stamp');

  static AotBinary resolve(Directory repoRoot) =>
      AotBinary._(File('${binDir(repoRoot).path}/${fileName()}'));
}
