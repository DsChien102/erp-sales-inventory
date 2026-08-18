import 'package:equatable/equatable.dart';

/// Reference to a provider invoice template.
final class ProviderTemplateRef extends Equatable {
  const ProviderTemplateRef({
    required this.templateId,
    required this.name,
    this.serial,
    this.symbol,
    this.isMtt = false,
    this.isAvailable = true,
  });

  final String templateId;
  final String name;
  final String? serial;
  final String? symbol;
  final bool isMtt;
  final bool isAvailable;

  @override
  List<Object?> get props => [
    templateId,
    name,
    serial,
    symbol,
    isMtt,
    isAvailable,
  ];
}
