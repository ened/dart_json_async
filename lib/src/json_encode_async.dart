part of json_async;

ReceivePort _jsonEncoderReceivePort = ReceivePort();

_encodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final encoded = jsonEncode(msg[0]);
    final SendPort replyPort = msg[1];
    replyPort.send(encoded);
  });
}

SendPort _jsonEncoderSendPort;

Future<String> _jsonEncodeAsyncOnPort(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first.then<String>((value) => value);
}

bool _encodeNotifiedAboutSpawnError = false;
Semaphore _encodeSemaphore = LocalSemaphore(1);

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
