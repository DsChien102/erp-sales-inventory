import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BasePrice extends ValueObject {
  const BasePrice({
    required this.amount,
    this.currency = 'VND',
  });

  final double amount;
  final String currency;

  @override
  List<Object?> get props => [amount, currency];
}
