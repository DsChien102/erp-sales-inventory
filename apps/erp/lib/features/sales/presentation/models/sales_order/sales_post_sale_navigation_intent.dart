/// Navigation intent emitted only after an authoritative post-sale precheck
/// returns `allowed`. The ERP page maps this to cancellation / return-exchange
/// routes.
enum SalesPostSaleNavigationIntent {
  cancel,
  returnExchange,
}
