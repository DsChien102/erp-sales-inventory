enum StockMode {
  basic,
  advanced;

  bool get isBasic => this == StockMode.basic;
  bool get isAdvanced => this == StockMode.advanced;
}
