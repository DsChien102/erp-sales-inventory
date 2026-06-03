import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../messaging_worker_loop.dart';

/// HTTP surface for Railway cron: health check and authenticated tick endpoint.
final class WorkerHttpServer {
  WorkerHttpServer({
    required MessagingWorkerLoop loop,
    required String tickSecret,
  }) : _loop = loop,
       _tickSecret = tickSecret;

  final MessagingWorkerLoop _loop;
  final String _tickSecret;

  Handler get handler {
    final router = Router()
      ..get('/health', _handleHealth)
      ..post('/tick', _handleTick);

    return Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  Future<HttpServer> serve({required int port}) {
    return shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  }

  Response _handleHealth(Request request) {
    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleTick(Request request) async {
    if (!_isAuthorized(request)) {
      return Response.forbidden(
        jsonEncode({'error': 'unauthorized'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final result = await _loop.runOnce();
    return Response.ok(
      jsonEncode(result.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  bool _isAuthorized(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) {
      return false;
    }
    final token = header.substring('Bearer '.length).trim();
    return token == _tickSecret;
  }
}
