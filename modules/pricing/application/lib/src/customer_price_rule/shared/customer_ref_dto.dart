final class CustomerRefDto {
  const CustomerRefDto({
    required this.customerId,
    required this.displayName,
    required this.status,
  });

  final String customerId;
  final String displayName;
  final String status;
}
