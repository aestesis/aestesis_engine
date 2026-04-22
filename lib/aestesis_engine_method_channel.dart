import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aestesis_engine_platform_interface.dart';

/// An implementation of [AestesisEnginePlatform] that uses method channels.
class MethodChannelAestesisEngine extends AestesisEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aestesis_engine');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
