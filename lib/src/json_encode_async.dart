part of json_async;

ReceivePort _jsonEncoderReceivePort = ReceivePort();

_encodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final SendPort replyPort = msg[1];

    try {
      final encoded = jsonEncode(msg[0]);
      replyPort.send(encoded);
    } catch (_) {
      // The only known testcase for this is by creating a cyclic array.
      // Unfortunately, the json encode method throws a invalid exception which
      // won't be catched properly, therefore we create a custom FormatException
      replyPort.send(FormatException('Invalid JSON object'));
    }
  });
}

SendPort _jsonEncoderSendPort;

Future<String> _jsonEncodeAsyncOnPort(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first.then((v) {
    if (v is Exception) {
      throw v;
    }
    return v;
  }).then<String>((value) => value);
}

bool _encodeNotifiedAboutSpawnError = false;
Semaphore _encodeSemaphore = LocalSemaphore(1);

/// Decodes a [json] string using Darts standard `jsonEncode` method.
/// Whenever the platform supports it, the call will be executed in a
/// long-running isolate.
Future<String> jsonEncodeAsync(dynamic json) async {
  if (_jsonEncoderSendPort == null) {
    await _encodeSemaphore.acquire();
    if (_jsonEncoderSendPort != null) {
      _encodeSemaphore.release();
    } else {
      try {
        await Isolate.spawn(_encodeJson, _jsonEncoderReceivePort.sendPort);
        _jsonEncoderSendPort = await _jsonEncoderReceivePort.first;
        _encodeSemaphore.release();
      } catch (e) {
        if (!_encodeNotifiedAboutSpawnError) {
          print('!! json_encode');
          print('!! Spawning the Isolate failed, encoding on main thread');
          print('!! Isolate name: ${Isolate.current.debugName}');
          print('!! $e');
          print('!! Flutter: https://github.com/flutter/flutter/issues/14815');
          _encodeNotifiedAboutSpawnError = true;
        }

        _encodeSemaphore.release();

        return jsonEncode(json);
      }
    }
  }

  return _jsonEncodeAsyncOnPort(_jsonEncoderSendPort, json);
}
