import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

final MethodChannel _channel = const MethodChannel('com.jarvanmo/flutter_oss')
  ..setMethodCallHandler(_handler);

StreamController<OSSResult> _uploadResultStream =
    new StreamController.broadcast();

/// Response from share
Stream<OSSResult> get uploadResultStream => _uploadResultStream.stream;

Future<dynamic> _handler(MethodCall methodCall) {
  if (methodCall.method == "FlutterOSS:uploadAsyncResult") {
    _uploadResultStream.add(OSSResult(
        isSuccess: methodCall.arguments["isSuccess"],
        completerId: methodCall.arguments["completerId"],
        code: methodCall.arguments["code"],
        remotePath: methodCall.arguments["remotePath"]));
  }
  return Future.value();
}

class OSSClient {
  static OSSClient _client;

  Map<String, Completer> _completerPool = {};

  StreamSubscription _streamSubscription;

  OSSClient._() {
    _streamSubscription = uploadResultStream.listen((result) {
      if (_completerPool.containsKey(result.completerId)) {
        var completer = _completerPool[result.completerId];
        completer.complete(result);
        _completerPool.remove(result.completerId);
      }
    });
  }

  factory OSSClient() {
    if (_client == null) {
      _client = OSSClient._();
    }
    return _client;
  }

  Future<OSSResult> uploadByPathAsync({
    @required String filePath,
    @required String objectName,
    @required String stsServer,
    @required String bucketName,
    @required String endpoint,
  }) async {
    assert(stsServer != null || stsServer.isNotEmpty);
    assert(bucketName != null || bucketName.isNotEmpty);
    var id = Uuid().v4();
    var completer = Completer<OSSResult>();

    _completerPool[id] = completer;
    await _channel.invokeMethod("FlutterOSS: uploadAsync", {
      "stsServer": stsServer,
      "bucketName": bucketName,
      "endpoint": endpoint,
      "completerId": id,
      "filePath": filePath,
      "objectName": objectName
    });
    return await completer.future;
  }
}

//"isSuccess" to true
//"completerId" to completerId
//"code" to 1
//"remotePath" to result.serverCallbackReturnBody
class OSSResult {
  final bool isSuccess;
  final String completerId;
  final int code;
  final String remotePath;

  OSSResult({this.isSuccess, this.completerId, this.code, this.remotePath});
}
