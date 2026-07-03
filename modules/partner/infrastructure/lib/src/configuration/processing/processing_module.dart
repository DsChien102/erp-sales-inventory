/// Build-trigger stub for vet45_generator processing builders
/// (`cqrs_internal_registry`, `cqrs_integration_event_registry`, etc.).
///
/// Partner messaging DI is wired in [PartnerStartup]; this file exists so
/// codegen can emit `generated/partner_*` artifacts.
final class ProcessingModule {
  const ProcessingModule();
}
