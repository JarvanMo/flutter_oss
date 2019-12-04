import 'dart:async';

import 'package:flutter/services.dart';

class FlutterOss {
  static const MethodChannel _channel =
      const MethodChannel('flutter_oss');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
