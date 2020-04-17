part of json_async;

ReceivePort _jsonDecoderReceivePort = ReceivePort();

_decodeJson(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    final decoded = jsonDecode(msg[0]);
    final SendPort replyPort = msg[1];
    replyPort.send(decoded);
  });
}

SendPort _jsonDecoderSendPort;

Future<T> _jsonDecodeAsyncOnPort<T>(SendPort send, message) {
  final ReceivePort receivePort = ReceivePort();
  send.send([message, receivePort.sendPort]);
  return receivePort.first.then<T>((value) => value);
}

bool _decodeNotifiedAboutSpawnError = false;
Semaphore _decodeSemaphore = LocalSemaphore(1);

Future<T> jsonDecodeAsync<T>(String json) async {
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
