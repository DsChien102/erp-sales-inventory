// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_partner_internal_command_client.dart';
import '../partner_command_pipeline.dart';

extension PartnerCommandBusBusinessCommands on CommandBus {
  void registerBusinessCommand<
      TCommand extends ICommand<TResult>, TResult, THandler extends Object>({
    required GetIt container,
    required Future<TResult> Function(TCommand command, THandler handler) invoke,
    ILogger? logger,
  }) {
    register<TCommand, TResult>((command) {
      final handler = container.get<THandler>();
      final pipeline = PartnerCommandPipeline.buildBusinessPipeline<
          TCommand, TResult, THandler>(
        container: container,
        handler: handler,
        invoke: invoke,
        logger: logger,
      );
      return pipeline(command);
    });
  }
}

extension PartnerCommandBusInternalCommands on CommandBus {
  void registerInternalCommand<TCommand extends InternalCommandBase<void>>({
    required GetIt container,
    required Future<void> Function(TCommand command) inner,
    required IPartnerInternalCommandClient commandClient,
    ILogger? logger,
  }) {
    register<TCommand, void>((command) {
      final pipeline = PartnerCommandPipeline.buildInternalPipeline<TCommand>(
        container: container,
        inner: inner,
        commandClient: commandClient,
        logger: logger,
      );
      return pipeline(command);
    });
  }
}
