import 'dart:convert';

import 'package:http/http.dart' as http;

import 'i_resend_client.dart';

/// Real Resend HTTP client. Missing API key → soft fail (no network).
final class ResendEmailClient implements IResendClient {
  ResendEmailClient({
    required String? apiKey,
    String fromEmail = 'Resend <onboarding@resend.dev>',
    http.Client? httpClient,
    Uri? endpoint,
  }) : _apiKey = apiKey,
       _fromEmail = fromEmail,
       _http = httpClient ?? http.Client(),
       _endpoint = endpoint ?? Uri.parse('https://api.resend.com/emails');

  final String? _apiKey;
  final String _fromEmail;
  final http.Client _http;
  final Uri _endpoint;

  @override
  Future<ResendSendResult> send({
    required String toEmail,
    required String subject,
    required String htmlBody,
    required String textBody,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      return const ResendSendResult.failed('missing_RESEND_API_KEY');
    }

    final response = await _http.post(
      _endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'from': _fromEmail,
        'to': <String>[toEmail],
        'subject': subject,
        'html': htmlBody,
        'text': textBody,
      }),
    );

    if (response.statusCode == 429) {
      return const ResendSendResult.failed(
        'resend_429_rate_limited',
        rateLimited: true,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return ResendSendResult.failed(
        'resend_${response.statusCode}: ${_truncate(response.body)}',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['id'] is String) {
        return ResendSendResult.ok(body['id'] as String);
      }
    } on Object {
      // fall through
    }
    return ResendSendResult.failed(
      'resend_invalid_response: ${_truncate(response.body)}',
    );
  }

  static String _truncate(String value, [int max = 200]) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}…';
  }
}
