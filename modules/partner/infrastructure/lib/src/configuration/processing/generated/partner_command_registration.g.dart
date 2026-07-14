// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:get_it/get_it.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../internal_commands/supabase_partner_internal_command_client.dart';
import 'partner_command_bus_extensions.g.dart';

abstract final class PartnerCommandRegistration {
  static void registerBusinessHandler<
      TCommand extends ICommand<TResult>, TResult, THandler extends Object>({
    required GetIt container,
    required CommandBus bus,
    required THandler Function() factory,
    ILogger? logger,
    Future<TResult> Function(TCommand command, THandler handler)? invoke,
  }) {
    if (!container.isRegistered<THandler>()) {
      container.registerFactory<THandler>(factory);
    }

    bus.registerBusinessCommand<TCommand, TResult, THandler>(
      container: container,
      logger: logger,
      invoke: invoke ?? (command, handler) => _defaultInvoke(command, handler),
    );
  }

  static Future<TResult> _defaultInvoke<
      TCommand extends ICommand<TResult>, TResult, THandler>(
    TCommand command,
    THandler handler,
  ) {
    if (handler is ICommandHandler<TCommand, TResult>) {
      return handler.handle(command);
    }

    throw StateError(
      'Handler ${handler.runtimeType} does not implement '
      'ICommandHandler<$TCommand, $TResult>. Provide a custom invoke callback.',
    );
  }

  static void registerInternalHandler<
      TCommand extends InternalCommandBase<void>, THandler extends Object>({
    required GetIt container,
    required CommandBus bus,
    required THandler Function() factory,
    required Future<void> Function(TCommand command) inner,
    required IPartnerInternalCommandClient commandClient,
    ILogger? logger,
  }) {
    if (!container.isRegistered<THandler>()) {
      container.registerFactory<THandler>(factory);
    }

    bus.registerInternalCommand<TCommand>(
      container: container,
      logger: logger,
      inner: inner,
      commandClient: commandClient,
    );
  }

  static void registerQueryHandler<
      TQuery extends IQuery<TResult>, TResult, THandler extends Object>({
    required QueryBus bus,
    required THandler Function() factory,
    required Future<TResult> Function(TQuery query, THandler handler) invoke,
  }) {
    final handler = factory();
    bus.register<TQuery, TResult>((query) => invoke(query, handler));
  }
}
