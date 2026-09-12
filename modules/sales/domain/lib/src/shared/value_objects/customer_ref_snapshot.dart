import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomerRefSnapshot extends ValueObject {
  CustomerRefSnapshot({
    this.customerId,
    required this.displayName,
    required this.isWalkIn,
  });

  final String? customerId;
  final String displayName;
  final bool isWalkIn;

  @override
  List<Object?> get props => [customerId, displayName, isWalkIn];
}
