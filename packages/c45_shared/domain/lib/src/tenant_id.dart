import 'value_object.dart';

class TenantId extends ValueObject {
  const TenantId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}
