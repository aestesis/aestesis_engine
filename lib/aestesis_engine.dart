
import 'aestesis_engine_platform_interface.dart';

class AestesisEngine {
  Future<String?> getPlatformVersion() {
    return AestesisEnginePlatform.instance.getPlatformVersion();
  }
}
