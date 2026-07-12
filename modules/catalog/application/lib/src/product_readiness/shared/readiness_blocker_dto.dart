final class ReadinessBlockerDto {
  const ReadinessBlockerDto({
    required this.code,
    required this.message,
    this.group,
  });

  final String code;
  final String message;
  final String? group;
}
