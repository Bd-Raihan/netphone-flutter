import 'package:flutter/services.dart';

class NativeCallService {
  static const MethodChannel _channel = MethodChannel(
    'com.netphoneapp.call/call_service',
  );

  static Future<void> start() async {
    await _channel.invokeMethod('startCallService');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopCallService');
  }
}
