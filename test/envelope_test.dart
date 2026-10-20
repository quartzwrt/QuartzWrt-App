import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/envelope.dart';

void main() {
  group('parseUbusResponse', () {
    test('ok envelope unwraps payload', () {
      final r = parseUbusResponse({
        'jsonrpc': '2.0',
        'id': 1,
        'result': [
          0,
          {
            'ok': true,
            'api': 1,
            'snapshot': {'v': 1},
            'access_token': 'x',
          },
        ],
      });
      expect(r.ok, isTrue);
      expect(r.api, 1);
      expect(r.data['access_token'], 'x');
      expect(r.data['snapshot'], {'v': 1});
      // 信封字段不泄漏进载荷
      expect(r.data.containsKey('ok'), isFalse);
      expect(r.data.containsKey('api'), isFalse);
    });

    test('in-band error envelope', () {
      final r = parseUbusResponse({
        'jsonrpc': '2.0',
        'id': 1,
        'result': [
          0,
          {
            'ok': false,
            'api': 1,
            'error': {
              'code': 'rate_limited',
              'message': 'too many failed attempts',
              'retry_after': 300,
            },
          },
        ],
      });
      expect(r.ok, isFalse);
      expect(r.error!.code, 'rate_limited');
      expect(r.error!.retryAfter, 300);
    });

    test('rpcd ACL denial maps to access_denied', () {
      final r = parseUbusResponse({
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32002, 'message': 'Access denied'},
      });
      expect(r.ok, isFalse);
      expect(r.error!.code, 'access_denied');
    });

    test('malformed bodies are transport errors', () {
      for (final body in <Map<String, dynamic>>[
        {'jsonrpc': '2.0', 'id': 1},
        {'jsonrpc': '2.0', 'id': 1, 'result': <dynamic>[]},
        {
          'jsonrpc': '2.0',
          'id': 1,
          'result': [1, {}],
        },
        {
          'jsonrpc': '2.0',
          'id': 1,
          'result': [0, 'not-a-map'],
        },
      ]) {
        final r = parseUbusResponse(body);
        expect(r.ok, isFalse, reason: '$body');
        expect(r.error!.code, 'transport', reason: '$body');
      }
    });
  });
}
