import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'aestesis_engine_method_channel.dart';

abstract class AestesisEnginePlatform extends PlatformInterface {
  /// Constructs a AestesisEnginePlatform.
  AestesisEnginePlatform() : super(token: _token);

  static final Object _token = Object();

  static AestesisEnginePlatform _instance = MethodChannelAestesisEngine();

  /// The default instance of [AestesisEnginePlatform] to use.
  ///
  /// Defaults to [MethodChannelAestesisEngine].
  static AestesisEnginePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AestesisEnginePlatform] when
  /// they register themselves.
  static set instance(AestesisEnginePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
