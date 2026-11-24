import 'package:erp/core/errors/app_exception.dart';
import 'package:supabase/supabase.dart';

import 'models/assistant_reply.dart';

/// Gọi Edge Function `ai-assistant`.
class AssistantRepository {
  AssistantRepository({required FunctionsClient functions}) : _functions = functions;

  final FunctionsClient _functions;

  Future<AssistantReply> ask({
    required String tenantId,
    required String question,
    required List<AssistantTurn> history,
  }) async {
    final FunctionResponse response;
    try {
      response = await _functions.invoke(
        'ai-assistant',
        body: <String, dynamic>{
          'tenant_id': tenantId,
          'question': question,
          'history': [for (final turn in history) turn.toJson()],
        },
      );
    } on FunctionsFetchException catch (error) {
      throw AppException(AppErrorCode.network, cause: error);
    } on FunctionException catch (error) {
      throw AppException(
        error.status == 401 ? AppErrorCode.authRequired : AppErrorCode.unknown,
        cause: error,
      );
    } catch (error, stackTrace) {
      throw AppException.from(error, stackTrace);
    }

    final data = response.data;
    if (data is! Map) throw const AppException(AppErrorCode.unknown);
    return AssistantReply.fromJson(Map<String, dynamic>.from(data));
  }
}
