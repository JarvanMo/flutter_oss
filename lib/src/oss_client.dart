import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

final MethodChannel _channel = const MethodChannel('com.jarvanmo/flutter_oss')
  ..setMethodCallHandler(_handler);

StreamController<OSSResult> _uploadResultStream =
    new StreamController.broadcast();

typedef OSSResultCallBack = void Function(OSSResult);

/// Response from share
Stream<OSSResult> get uploadResultStream => _uploadResultStream.stream;

Future<dynamic> _handler(MethodCall methodCall) {
  if (methodCall.method == "FlutterOSS:uploadAsyncResult") {
    _uploadResultStream.add(OSSResult(
        isSuccess: methodCall.arguments["isSuccess"],
        completerId: methodCall.arguments["completerId"],
        code: methodCall.arguments["code"],
        remotePath: methodCall.arguments["remotePath"],
        message: methodCall.arguments['message']));
  }
  return Future.value();
}

class OSSClient {
  static OSSClient _client;

  Map<String, Completer> _completerPool = {};
  Map<String, OSSResultCallBack> _callbackPool = {};

  StreamSubscription _streamSubscription;

  OSSClient._() {
    _streamSubscription = uploadResultStream.listen((result) {
      if (_callbackPool.containsKey(result.completerId)) {
        var completer = _callbackPool[result.completerId];
        completer(result);
        _callbackPool.remove(result.completerId);
      }
    });
  }

  factory OSSClient() {
    if (_client == null) {
      _client = OSSClient._();
    }
    return _client;
  }

  Future uploadByPathAsync({
    @required String filePath,
    @required String objectName,
    @required String stsServer,
    @required String bucketName,
    @required String endpoint,
    @required OSSResultCallBack callback,
    String completerId,
  }) async {
    assert(stsServer != null || stsServer.isNotEmpty);
    assert(bucketName != null || bucketName.isNotEmpty);
    var id = completerId ?? Uuid().v4();
    var completer = Completer<OSSResult>();

    _completerPool[id] = completer;
    _callbackPool[id] = callback;
    await _channel.invokeMethod("FlutterOSS: uploadAsync", {
      "stsServer": stsServer,
      "bucketName": bucketName,
      "endpoint": endpoint,
      "completerId": id,
      "filePath": filePath,
      "objectName": objectName
    });
    return Future.value();
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
  final String message;

  OSSResult(
      {this.isSuccess,
      this.completerId,
      this.code,
      this.remotePath,
      this.message});
}
