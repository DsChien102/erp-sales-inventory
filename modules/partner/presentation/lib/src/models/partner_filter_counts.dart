class PartnerFilterCounts {
  const PartnerFilterCounts({
    this.total = 0,
    this.customer = 0,
    this.supplier = 0,
    this.both = 0,
    this.individual = 0,
    this.company = 0,
    this.household = 0,
    this.active = 0,
    this.inactive = 0,
  });

  final int total;
  final int customer;
  final int supplier;
  final int both;
  final int individual;
  final int company;
  final int household;
  final int active;
  final int inactive;
}
