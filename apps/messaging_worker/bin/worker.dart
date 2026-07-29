import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:messaging_worker/http/worker_http_server.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/worker_tick_scheduler.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'once',
      help: 'Run one messaging tick and exit.',
      negatable: false,
    )
    ..addFlag(
      'serve',
      help: 'Start HTTP server with GET /health, POST /tick, and adaptive self-loop.',
      negatable: false,
    )
    ..addOption(
      'port',
      defaultsTo: '8080',
      help: 'HTTP port when using --serve (overridden by PORT env).',
    );

  final results = parser.parse(arguments);
  final runOnce = results['once'] as bool;
  final runServe = results['serve'] as bool;

  if (runOnce == runServe) {
    stderr.writeln('Specify exactly one mode: --once or --serve');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final config = WorkerEnv.fromPlatform();
  configurePackageLogging(level: config.logLevel);

  final workerEnvironment = _resolveWorkerEnvironment(
    Platform.environment,
  );
  stdout.writeln(
    jsonEncode({
      'event': 'worker_startup',
      'environment': workerEnvironment,
      'mode': runOnce ? 'once' : 'serve',
      'supabaseHost': Uri.parse(config.supabaseUrl).host,
      'resendConfigured': config.resendApiKey != null,
      'appLinkConfigured': config.appLinkBaseUrl != null,
      'logLevel': config.logLevel.name,
    }),
  );

  final context = await MessagingWorkerBootstrap.bootstrap(
    config: config,
    loggerFactory: const LoggingLoggerFactory(),
  );
  final loop = MessagingWorkerLoop(context: context);

  if (runOnce) {
    final tickResult = await loop.runOnce();
    stdout.writeln(jsonEncode(tickResult.toJson()));
    exit(tickResult.errorsCount > 0 ? 1 : 0);
  } else {
    final port = int.parse(Platform.environment['PORT'] ?? results['port'] as String);
    final server = WorkerHttpServer(
      loop: loop,
      tickSecret: context.config.tickSecret,
    );
    final httpServer = await server.serve(port: port);
    stdout.writeln('Messaging worker listening on port ${httpServer.port}');

    final scheduler = WorkerTickScheduler(
      loop: loop,
      policy: context.config.toTickPolicy(),
    );
    scheduler.start();

    final shutdown = Completer<void>();
    ProcessSignal.sigterm.watch().listen((_) {
      if (!shutdown.isCompleted) {
        shutdown.complete();
      }
    });
    ProcessSignal.sigint.watch().listen((_) {
      if (!shutdown.isCompleted) {
        shutdown.complete();
      }
    });
    await shutdown.future;
    scheduler.stop();
    await httpServer.close(force: true);
  }
}

String _resolveWorkerEnvironment(Map<String, String> environment) {
  final explicit = environment['WORKER_ENV']?.trim();
  if (explicit != null && explicit.isNotEmpty && explicit != 'unknown') {
    return explicit;
  }

  final railway = environment['RAILWAY_ENVIRONMENT_NAME']?.trim();
  if (railway != null && railway.isNotEmpty) {
    return railway;
  }

  return explicit?.isNotEmpty == true ? explicit! : 'unknown';
}
