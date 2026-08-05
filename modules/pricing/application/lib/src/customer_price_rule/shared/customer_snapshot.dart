final class CustomerSnapshot {
  const CustomerSnapshot({
    required this.customerId,
    required this.displayName,
    this.phone,
    required this.status,
    required this.exists,
    required this.isCustomer,
  });

  final String customerId;
  final String displayName;
  final String? phone;
  final String status;
  final bool exists;
  final bool isCustomer;

  bool get isValidForTransaction => exists && isCustomer && status == 'active';
}

