/// Named fake scenarios from harness/07-api-contracts.md §S15 (+ Admin auth).
enum FakeIamScenario {
  /// Default happy path: searchable users + detail + lifecycle + onboarding.
  usersSearchOk,
  userDetailOk,
  userForbidden403,
  activationResendOk,
  suspendOk,
  restoreOk,
  onboardingExistingUserOk,
  onboardingNewUserOk,
  onboardingRetryIdempotent,
  onboardingValidationError,
  authOk,
  authInvalid,
}
