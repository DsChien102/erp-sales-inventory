import 'package:get_it/get_it.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Registers shared [IEventsBus] into the IAM container.
final class EventsBusModule {
  const EventsBusModule({this.eventsBus});

  final IEventsBus? eventsBus;

  void load(GetIt container) {
    container.registerSingleton<IEventsBus>(
      eventsBus ?? InMemoryEventBusClient(),
    );
  }
}
