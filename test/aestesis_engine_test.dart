import 'package:flutter_test/flutter_test.dart';
import 'package:aestesis_engine/aestesis_engine.dart';
import 'package:aestesis_engine/aestesis_engine_platform_interface.dart';
import 'package:aestesis_engine/aestesis_engine_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAestesisEnginePlatform
    with MockPlatformInterfaceMixin
    implements AestesisEnginePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AestesisEnginePlatform initialPlatform = AestesisEnginePlatform.instance;

  test('$MethodChannelAestesisEngine is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAestesisEngine>());
  });

  test('getPlatformVersion', () async {
    AestesisEngine aestesisEnginePlugin = AestesisEngine();
    MockAestesisEnginePlatform fakePlatform = MockAestesisEnginePlatform();
    AestesisEnginePlatform.instance = fakePlatform;

    expect(await aestesisEnginePlugin.getPlatformVersion(), '42');
  });
}
