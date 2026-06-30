import '../../value_objects/phone_number.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PhoneRequiredRule implements IBusinessRule {
  PhoneRequiredRule(PhoneNumber? phone) : _phone = phone;

  final PhoneNumber? _phone;

  @override
  bool isBroken() => _phone == null;

  @override
  String get message => 'Partner phone is required.';
}
