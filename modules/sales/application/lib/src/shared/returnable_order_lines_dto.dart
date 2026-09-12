import 'returnable_order_line_dto.dart';

final class ReturnableOrderLinesDto {
  ReturnableOrderLinesDto({
    required this.salesOrderId,
    required this.sourceVersion,
    required List<ReturnableOrderLineDto> lines,
  }) : lines = List.unmodifiable(lines);

  final String salesOrderId;
  final int sourceVersion;
  final List<ReturnableOrderLineDto> lines;
}
