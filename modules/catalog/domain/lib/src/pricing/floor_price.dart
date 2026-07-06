import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class FloorPrice extends ValueObject {
  const FloorPrice({
    required this.amount,
    this.currency = 'VND',
  });

  final double amount;
  final String currency;

  @override
  List<Object?> get props => [amount, currency];
}
