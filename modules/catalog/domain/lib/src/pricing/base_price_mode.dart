enum BasePriceMode {
  manual,
  costingModule;

  bool get isManual => this == BasePriceMode.manual;
  bool get isCostingModule => this == BasePriceMode.costingModule;
}
