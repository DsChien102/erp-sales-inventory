/// Triggers a one-shot messaging drain after a successful UI mutation.
abstract interface class IMessagingFlushPort {
  Future<void> flushAfterMutation();
}
