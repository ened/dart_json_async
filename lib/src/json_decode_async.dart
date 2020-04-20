part of json_async;

ReceivePort _jsonDecoderReceivePort = ReceivePort();

_decodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final SendPort replyPort = msg[1];

    try {
      final decoded = jsonDecode(msg[0]);
      replyPort.send(decoded);
    } catch (e) {
      replyPort.send(e);
    }
  });
}

SendPort _jsonDecoderSendPort;

Future<dynamic> _jsonDecodeAsyncOnPort(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first.then((v) {
    if (v is Exception) {
      throw v;
    }
    return v;
  });
}

bool _decodeNotifiedAboutSpawnError = false;
Semaphore _decodeSemaphore = LocalSemaphore(1);

/// Decodes a [json] string using Darts standard `jsonDecode` method.
/// Whenever the platform supports it, the call will be executed in a
/// long-running isolate.
Future<dynamic> jsonDecodeAsync(String json) async {
  if (_jsonDecoderSendPort == null) {
    await _decodeSemaphore.acquire();
    if (_jsonDecoderSendPort != null) {
      _decodeSemaphore.release();
    } else {
      try {
        await Isolate.spawn(_decodeJson, _jsonDecoderReceivePort.sendPort);
        _jsonDecoderSendPort = await _jsonDecoderReceivePort.first;
        _decodeSemaphore.release();
      } catch (e) {
        if (!_decodeNotifiedAboutSpawnError) {
          print('!! json_decode');
          print('!! Spawning the Isolate failed, decoding on main thread');
          print('!! Isolate name: ${Isolate.current.debugName}');
          print('!! $e');
          print('!! Flutter: https://github.com/flutter/flutter/issues/14815');
          _decodeNotifiedAboutSpawnError = true;
        }

        _decodeSemaphore.release();

        return jsonDecode(json);
      }
    }
  }

  return _jsonDecodeAsyncOnPort(_jsonDecoderSendPort, json);
}

/// Helper method that uses `jsonDecodeAsync` to decode the passed [json] string
/// into a typed `List`.
Future<List<T>> jsonDecodeAsyncList<T>(String json) async {
  return jsonDecodeAsync(json).then((value) {
    if (value is List) {
      return List<T>.from(value);
    }

    throw TypeError();
  });
}

/// Helper method that uses `jsonDecodeAsync` to decode the passed [json] string
/// into a typed `Map`. Because JSON dictionaries can only contain string keys,
/// the returned Map type is `String,T`.
Future<Map<String, T>> jsonDecodeAsyncMap<T>(String json) async {
  return jsonDecodeAsync(json).then((value) {
    if (value is Map) {
      return Map<String, T>.from(value);
    }

    throw TypeError();
  });
}
