import '../../value_objects/partner_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerNameRequiredRule implements IBusinessRule {
  PartnerNameRequiredRule(PartnerName? name) : _name = name;

  final PartnerName? _name;

  @override
  bool isBroken() => _name == null;

  @override
  String get message => 'Partner display name is required.';
}
