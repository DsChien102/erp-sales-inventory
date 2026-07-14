/// Soft-delete eligibility check result.
final class DeleteEligibilityDto {
  const DeleteEligibilityDto({
    required this.eligible,
    this.reason,
  });

  final bool eligible;
  final String? reason;
}
