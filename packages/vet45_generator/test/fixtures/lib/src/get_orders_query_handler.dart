import 'cqrs.dart';

class GetOrdersQuery implements ICommand<OrdersDto> {
  @override
  String get id => 'id';
}

class OrdersDto {}

abstract class ReadGateway {}

final class GetOrdersQueryHandler
    implements IQueryHandler<GetOrdersQuery, OrdersDto> {
  GetOrdersQueryHandler({required this.readGateway});

  final ReadGateway readGateway;

  @override
  Future<OrdersDto> handle(GetOrdersQuery query) async => OrdersDto();
}
