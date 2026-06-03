import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:messaging_worker/http/worker_http_server.dart';
import 'package:messaging_worker/messaging_worker_bootstrap.dart';
import 'package:messaging_worker/messaging_worker_loop.dart';
import 'package:messaging_worker/worker_tick_scheduler.dart';

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

  final context = MessagingWorkerBootstrap.bootstrap();
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
