import 'partner_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BankAccount extends ValueObject {
  BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  }) {
    if (accountNumber.trim().isEmpty) {
      throw DomainException('Bank account number must not be empty.');
    }
  }

  final PartnerName bankName;
  final String accountNumber;
  final PartnerName accountHolder;

  @override
  List<Object?> get props => [bankName, accountNumber, accountHolder];
}
