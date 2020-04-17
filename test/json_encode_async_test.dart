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
  });
}
