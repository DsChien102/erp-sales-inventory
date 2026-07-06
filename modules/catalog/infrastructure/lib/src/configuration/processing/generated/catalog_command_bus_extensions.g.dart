// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_catalog_internal_command_client.dart';
import '../catalog_command_pipeline.dart';

extension CatalogCommandBusBusinessCommands on CommandBus {
  void
  registerBusinessCommand<TCommand extends ICommand<TResult>, TResult, THandler extends Object>({
    required GetIt container,
    required Future<TResult> Function(TCommand command, THandler handler) invoke,
    ILogger? logger,
  }) {
    register<TCommand, TResult>((command) {
      final handler = container.get<THandler>();
      final pipeline = CatalogCommandPipeline.buildBusinessPipeline<TCommand, TResult, THandler>(
        container: container,
        handler: handler,
        invoke: invoke,
        logger: logger,
      );
      return pipeline(command);
    });
  }
}

extension CatalogCommandBusInternalCommands on CommandBus {
  void registerInternalCommand<TCommand extends InternalCommandBase<void>>({
    required GetIt container,
    required Future<void> Function(TCommand command) inner,
    required ICatalogInternalCommandClient commandClient,
    ILogger? logger,
  }) {
    register<TCommand, void>((command) {
      final pipeline = CatalogCommandPipeline.buildInternalPipeline<TCommand>(
        container: container,
        inner: inner,
        commandClient: commandClient,
        logger: logger,
      );
      return pipeline(command);
    });
  }
}
