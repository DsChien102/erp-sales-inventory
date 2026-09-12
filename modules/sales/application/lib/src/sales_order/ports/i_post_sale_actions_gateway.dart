import '../../shared/available_post_sale_actions_dto.dart';
import '../queries/get_available_post_sale_actions/get_available_post_sale_actions_query.dart';

abstract interface class IPostSaleActionsGateway {
  Future<AvailablePostSaleActionsDto> getAvailableActions(
    GetAvailablePostSaleActionsQuery query,
  );
}
