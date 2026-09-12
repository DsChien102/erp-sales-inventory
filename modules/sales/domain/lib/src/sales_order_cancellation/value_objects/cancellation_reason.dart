import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CancellationReason extends ValueObject {
  CancellationReason._({required this.text});

  factory CancellationReason.create({String? reasonText}) {
    return CancellationReason._(text: (reasonText ?? '').trim());
  }

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}
