import 'package:json_async/json_async.dart';
import 'package:test/test.dart';

void main() {
  group('jsonEncodeAsync', () {
    test('simple types', () async {
      expect(await jsonEncodeAsync(23), '23');
      expect(await jsonEncodeAsync('123'), '"123"');
      expect(await jsonEncodeAsync(23.1), '23.1');
    });

    test('complex types', () async {
      expect(await jsonEncodeAsync(['A', 'B']), '["A","B"]');
      expect(await jsonEncodeAsync({'A': 'B'}), '{"A":"B"}');
    });

    test('forwards & recovers from error', () async {
      try {
        List<dynamic> a = [1, 2, 3];
        a.add(a);

        await jsonEncodeAsync(a);

        fail('should fail with an error');
      } on FormatException catch (e) {
        expect(e.message, 'Invalid JSON object');
      }

      expect(await jsonEncodeAsync('ABC'), '"ABC"');
    });
  });
}
