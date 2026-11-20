sealed class SalesDraftPickResult {
  const SalesDraftPickResult();
}

final class SalesDraftPickNew extends SalesDraftPickResult {
  const SalesDraftPickNew();
}

final class SalesDraftPickExisting extends SalesDraftPickResult {
  const SalesDraftPickExisting(this.draftId);

  final String draftId;
}
