/// Build-time failure with a stable diagnostic prefix.
final class CodegenDiagnostic implements Exception {
  CodegenDiagnostic(this.phase, this.message);

  final String phase;
  final String message;

  @override
  String toString() => 'vet45_generator:$phase: $message';
}
