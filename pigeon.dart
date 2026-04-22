import 'package:pigeon/pigeon.dart';

/*
// supported data types

Dart	                Swift
null	                nil
bool	                NSNumber(value: Bool)
int	                  NSNumber(value: Int32)
int,                  if 32 bits not enough	NSNumber(value: Int)
double	              NSNumber(value: Double)
String	              String
Uint8List	            FlutterStandardTypedData(bytes: Data)
Int32List	            FlutterStandardTypedData(int32: Data)
Int64List	            FlutterStandardTypedData(int64: Data)
Float32List	          FlutterStandardTypedData(float32: Data)
Float64List	          FlutterStandardTypedData(float64: Data)
List	                Array
Map	                  Dictionary

*/

/*
    CBOR: binary json

  https://pub.dev/packages/cbor

*/

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/interface/messages.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'darwin/aestesis_engine/Sources/aestesis_engine/pigeon/messages.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'aestesis_engine',
))
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Preview {
  final String moduleId;
  final String? assetId;
  final int width;
  final int height;
  final Uint8List data;
  Preview({
    required this.moduleId,
    this.assetId,
    required this.width,
    required this.height,
    required this.data,
  });
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
class AudioLevel {
  final double peak;
  final Equalizer eq;
  AudioLevel({
    required this.peak,
    required this.eq,
  });
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
class Equalizer {
  final double low;
  final double mid;
  final double high;
  Equalizer({
    required this.low,
    required this.mid,
    required this.high,
  });
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Asset {
  final String id;
  String name;
  String? uri;
  // Uint8List? data;
  Asset({required this.id, required this.name, this.uri});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum ControlType { float, unit, integer, boolean, color }

// float: [-1,1]]
// unit: [0, 1]  I  // https://en.wikipedia.org/wiki/Unit_interval
// integer: [0,..]  // sometime -1 is used as undefined
// boolean: 0 or 1
// color: 0xAARRGGBB in count variable

enum AnalogControl { zoom, blur, hue, saturation, brightness, white }

enum AnalogSourceControl { opacity, color, blendMode, gain }

enum CameraControl { asset }

enum FxControl { asset, level }

enum LutControl { asset, fade, intensity }

enum PlayerControl { asset, position }

enum ShaderControl { asset }

enum SynControl { asset }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Control {
  final String moduleId;
  final String id;
  final ControlType type;
  final String name;
  double value;
  int count; // count of integer or color
  Control(
      {required this.id,
      required this.moduleId,
      required this.name,
      required this.type,
      this.count = 1,
      this.value = 0.0});
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
enum ControlBlendMode {
  normal,
  add,
  subtract,
  multiply,
  difference,
  exclusion,
  negation,
  luma,
  lumaAdd,
  lumaSubtract,
  lumaMultiply,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  linearLight,
  linearBurn,
  glow,
  phoenix,
  reflect
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Composition {
  final String id;
  String name;
  List<Module?> modules;
  Composition({required this.id, required this.name, required this.modules});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum ModuleType { analog, camera, fx, lut, player, shader, syn }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Module {
  final String id;
  final ModuleType type;
  String name;
  List<Control?>? controls;
  List<Asset?>? assets;
  Module(
      {required this.id,
      required this.type,
      required this.name,
      this.controls,
      this.assets});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum CameraPosition { undefined, front, back, virtual }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum CameraType { undefined, builtin, deskview, continuity, external }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CameraDevice {
  final String id;
  final String name;
  final String model;
  final String manufacturer;
  final CameraPosition position;
  final CameraType type;
  CameraDevice(
      {required this.id,
      required this.name,
      required this.model,
      required this.manufacturer,
      required this.position,
      required this.type});
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
class AudioDevice {
  final int id;
  final String name;
  final String manufacturer;
  final List<String?> inputChannels;
  final List<String?> outputChannels;
  AudioDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.inputChannels,
    required this.outputChannels,
  });
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AudioSettings {
  String deviceName;
  int leftChannel;
  int rightChannel;
  AudioSettings(
      {required this.deviceName,
      required this.leftChannel,
      required this.rightChannel});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionSettings {
  double width;
  double height;
  double fps;
  AudioSettings? audioSettings;
  CompositionSettings(
      {required this.width,
      required this.height,
      required this.fps,
      this.audioSettings});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionStatistics {
  double fps;
  double cpu;
  double gpu;
  double ram;
  CompositionStatistics(
      {required this.fps,
      required this.cpu,
      required this.gpu,
      required this.ram});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionStates {
  bool recording;
  bool streaming;
  bool previewing;
  CompositionStates({
    this.recording = false,
    this.streaming = false,
    this.previewing = false,
  });
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
@HostApi()
abstract class AestesisEngineApi {
  Composition newComposition();
  Composition composition();
  Composition updateComposition(Composition composition);
  CompositionSettings settings(CompositionSettings? settings);
  Composition updateModule(Module module);
  Composition addModule(Module module);
  Composition insertModule(Module module, int index);
  Composition removeModule(String moduleId);
  Composition addAssets(String moduleId, List<Asset?> assets);
  Composition removeAssets(String moduleId, List<String?> assetIds);
  void updateControl(Control control);
  void outputView(bool show);
  void startRecording(String path);
  void stopRecording();

  @async
  List<CameraDevice> cameraDevices();
  @async
  List<AudioDevice> audioDevices();
  @async
  List<String> pickFiles(
      String title, String? directory, bool multiple, List<String> extensions);

  void setAssetData(String key, String json);
  String? getAssetData(String key);
  void setAssetDatas(String json);
  String? getAssetDatas();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum MessageLevel { info, warning, error }

//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AssetTexture {
  final String moduleId;
  final String assetId;
  final int textureId;
  AssetTexture({
    required this.moduleId,
    required this.assetId,
    required this.textureId,
  });
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
@FlutterApi()
abstract class MessageAestesisEngineApi {
  void texture(AssetTexture asset);
  void message(MessageLevel level, String message);
  void preview(Preview preview);
  void statistics(CompositionStatistics statistics);
  void control(Control control);
  void audio(AudioLevel level);
  void states(CompositionStates states);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
