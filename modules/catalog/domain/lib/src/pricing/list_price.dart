import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ListPrice extends ValueObject {
  const ListPrice({
    required this.amount,
    this.currency = 'VND',
  });

  final double amount;
  final String currency;

  @override
  List<Object?> get props => [amount, currency];
}
