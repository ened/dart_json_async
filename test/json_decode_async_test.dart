import 'package:json_async/json_async.dart';
import 'package:test/test.dart';

void main() {
  group('jsonDecodeAsync', () {
    test('string', () async => expect(await jsonDecodeAsync('"ABC"'), 'ABC'));
    test('int', () async => expect(await jsonDecodeAsync('5'), 5));
    test('double', () async => expect(await jsonDecodeAsync('12.2'), 12.2));
  });

  group('jsonDecodeAsyncList', () {
    test('int list', () async {
      final List<int> result = await jsonDecodeAsyncList<int>('[0,1,2]');

      expect(result, <int>[0, 1, 2]);
    });

    test('string list', () async {
      final List<String> result =
          await jsonDecodeAsyncList<String>('["A","B"]');

      expect(result, <String>['A', 'B']);
    });

    test('dynamic list', () async {
      final List<dynamic> result =
          await jsonDecodeAsyncList<dynamic>('[0,"ABC"]');

      expect(result, <dynamic>[0, 'ABC']);
    });

    test('throws TypeError', () async {
      try {
        await jsonDecodeAsyncList<dynamic>('1');
        fail('did not throw exception');
      } on TypeError catch (_) {
        // pass
      }
    });
  });

  group('jsonDecodeAsyncMap', () {
    test('int map', () async {
      final Map<String, int> result = await jsonDecodeAsyncMap<int>('{"0":1}');

      expect(result, <String, int>{'0': 1});
    });
    test('string map', () async {
      final Map<String, String> result =
          await jsonDecodeAsyncMap<String>('{"A":"B"}');

      expect(result, <String, String>{'A': 'B'});
    });

    test('dynamic map', () async {
      final Map<String, dynamic> result =
          await jsonDecodeAsyncMap<dynamic>('{"0":1, "1":"ABC"}');

      expect(result, <String, dynamic>{'0': 1, '1': 'ABC'});
    });

    test('throws TypeError', () async {
      try {
        await jsonDecodeAsyncMap<dynamic>('1');
        fail('did not throw exception');
      } on TypeError catch (_) {
        // pass
      }
    });
  });
}
