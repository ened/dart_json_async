# json_async

Runs JSON encoding/decoding in a separate, long-running, isolate.

This is helpful when working with JSON frequently and the spawning/destruction or a new isolate (e.g. when used in via [compute](https://api.flutter.dev/flutter/foundation/compute.html)) creates too much overhead.

## Example

``` dart
final String str = await jsonDecodeAsync('"ABC"');

final Map<String, int> map = await jsonDecodeAsyncMap<int>('{"0":1}');

final List<String> list = await jsonDecodeAsyncList<String>('["A","B"]');
```

All 3 calls will be run in _sequentially_ a shared background isolate.