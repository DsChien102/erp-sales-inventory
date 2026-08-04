final class CustomerRefDto {
  const CustomerRefDto({
    required this.customerId,
    required this.displayName,
    this.phone,
    required this.status,
  });

  final String customerId;
  final String displayName;
  final String? phone;
  final String status;
}

