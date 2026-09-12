import '../sales_order/ports/i_post_sale_actions_gateway.dart';
import '../sales_order/queries/get_available_post_sale_actions/get_available_post_sale_actions_query.dart';
import '../shared/available_post_sale_actions_dto.dart';

final class FakePostSaleActionsGateway implements IPostSaleActionsGateway {
  FakePostSaleActionsGateway({
    AvailablePostSaleActionsDto? actions,
    this.error,
  }) : _actions = actions;

  final AvailablePostSaleActionsDto? _actions;
  final Object? error;

  int actionsCalls = 0;

  @override
  Future<AvailablePostSaleActionsDto> getAvailableActions(
    GetAvailablePostSaleActionsQuery query,
  ) async {
    actionsCalls += 1;
    if (error != null) throw error!;
    return _actions ??
        const AvailablePostSaleActionsDto(
          canCancel: true,
          canReturnExchange: true,
        );
  }
}
