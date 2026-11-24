import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/assistant/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  late _MockFunctions functions;
  late AssistantRepository repository;

  setUp(() {
    functions = _MockFunctions();
    repository = AssistantRepository(functions: functions);
  });

  When<Future<FunctionResponse>> stubInvoke() =>
      when(() => functions.invoke(any(), body: any(named: 'body')));

  Future<AssistantReply> ask() => repository.ask(
    tenantId: 'T',
    question: 'Q',
    history: const [AssistantTurn(role: 'user', text: 'a')],
  );

  test('ask sends snake_case body', () async {
    stubInvoke().thenAnswer(
      (_) async => FunctionResponse(status: 200, data: {'trang_thai': 'ok', 'cau_tra_loi': 'x'}),
    );
    await ask();
    verify(
      () => functions.invoke(
        'ai-assistant',
        body: {
          'tenant_id': 'T',
          'question': 'Q',
          'history': [
            {'role': 'user', 'text': 'a'},
          ],
        },
      ),
    ).called(1);
  });

  test('parses all 9 trang_thai values', () async {
    const map = {
      'ok': AssistantStatus.ok,
      'tro_chuyen': AssistantStatus.troChuyen,
      'ngoai_pham_vi': AssistantStatus.ngoaiPhamVi,
      'chua_ho_tro': AssistantStatus.chuaHoTro,
      'tu_choi': AssistantStatus.tuChoi,
      'khong_quyen': AssistantStatus.khongQuyen,
      'loi': AssistantStatus.loi,
      'het_luot': AssistantStatus.hetLuot,
      'ban': AssistantStatus.ban,
    };
    for (final e in map.entries) {
      stubInvoke().thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {'trang_thai': e.key, 'cau_tra_loi': 'hi', 'luot_con_lai': 7, 'cong_cu': ['t']},
        ),
      );
      final reply = await ask();
      expect(reply.status, e.value);
      expect(reply.text, 'hi');
      expect(reply.remaining, 7);
      expect(reply.tools, ['t']);
    }
  });

  test('parses table block with open target and null cell', () async {
    stubInvoke().thenAnswer(
      (_) async => FunctionResponse(
        status: 200,
        data: {
          'trang_thai': 'ok',
          'cau_tra_loi': 'x',
          'khoi': [
            {
              'loai': 'bang',
              'tieu_de': 'Top',
              'cot': [
                {'khoa': 'ten', 'ten': 'Sản phẩm', 'kieu': 'chu'},
                {'khoa': 'lai', 'ten': 'Lãi', 'kieu': 'tien'},
              ],
              'dong': [
                {
                  'o': {'ten': 'A', 'lai': null},
                  'mo': {'loai': 'san_pham', 'id': 'p1'},
                },
                {
                  'o': {'ten': 'B', 'lai': -5},
                },
              ],
            },
          ],
        },
      ),
    );
    final reply = await ask();
    final block = reply.blocks.single;
    expect(block.title, 'Top');
    expect(block.columns[1].kind, ColumnKind.tien);
    expect(block.rows[0].cells['lai'], isNull);
    expect(block.rows[0].open?.loai, 'san_pham');
    expect(block.rows[0].open?.id, 'p1');
    expect(block.rows[1].open, isNull);
    expect(block.rows[1].cells['lai'], -5);
  });

  test('unknown trang_thai falls back to loi; missing khoi is empty', () async {
    stubInvoke().thenAnswer(
      (_) async => FunctionResponse(status: 200, data: {'trang_thai': 'zzz', 'cau_tra_loi': 'x'}),
    );
    final reply = await ask();
    expect(reply.status, AssistantStatus.loi);
    expect(reply.blocks, isEmpty);
  });

  test('FunctionsFetchException maps to network', () async {
    stubInvoke().thenThrow(FunctionsFetchException(details: 'offline'));
    await expectLater(
      ask(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.network)),
    );
  });

  test('FunctionException 401 maps to authRequired, others to unknown', () async {
    stubInvoke().thenThrow(FunctionException(status: 401));
    await expectLater(
      ask(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.authRequired)),
    );
    for (final status in [400, 405, 500]) {
      stubInvoke().thenThrow(FunctionException(status: status));
      await expectLater(
        ask(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.unknown)),
      );
    }
  });
}
