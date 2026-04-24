import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'messages.g.dart';
import 'messages.g.dart' as mess;

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CompositionSettingsExtension on CompositionSettings {
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'fps': fps,
      if (audioSettings != null) 'audio': audioSettings!.toJson()
    };
  }

  static CompositionSettings fromJson(Map<String, dynamic> json) {
    return CompositionSettings(
      width: json['width'],
      height: json['height'],
      fps: json['fps'],
      audioSettings: json['audio'] != null
          ? AudioSettingsExtension.fromJson(json['audio'])
          : null,
    );
  }
}

extension AudioSettingsExtension on AudioSettings {
  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'leftChannel': leftChannel,
      'rightChannel': rightChannel,
    };
  }

  static AudioSettings fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      deviceName: json['deviceName'] ?? 'unknown',
      leftChannel: json['leftChannel'],
      rightChannel: json['rightChannel'],
    );
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CompositionExtension on Composition {
  void upgrade() {
    for (final module in modules.whereType<Module>()) {
      module.upgrade();
    }
  }

  Composition copyWith({String? name, List<Module?>? modules}) {
    return Composition(
      id: id,
      name: name ?? this.name,
      modules: modules ?? this.modules,
    );
  }

  bool equals(Composition other) {
    return id == other.id &&
        name == other.name &&
        modules.length == other.modules.length;
  }

  List<Module> diff(Composition other) {
    final List<Module> different = [];
    for (final module in modules.whereType<Module>()) {
      final otherModule = other.modules
          .whereType<Module>()
          .firstWhere((m) => m.id == module.id);
      if (!module.equals(otherModule)) {
        different.add(module);
      }
    }
    return different;
  }

  Module? getModule(String id) {
    return modules.whereType<Module>().firstWhereOrNull((m) => m.id == id);
  }

  Module operator [](String id) {
    return modules.whereType<Module>().firstWhere((m) => m.id == id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modules': modules.map((m) => m?.toJson()).toList(),
    };
  }

  static Composition fromJson(Map<String, dynamic> json) {
    final composition = Composition(
      id: json['id'],
      name: json['name'],
      modules: [...json['modules']?.map((m) => ModuleExtension.fromJson(m))],
    );
    composition.upgrade();
    return composition;
  }

  static Composition create() {
    final id = const Uuid().v4();
    return Composition(id: id, name: 'Composition', modules: []);
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ControlBlendModeExtension on ControlBlendMode {
  String get name {
    switch (this) {
      case ControlBlendMode.normal:
        return 'Normal';
      case ControlBlendMode.add:
        return 'Add';
      case ControlBlendMode.subtract:
        return 'Subtract';
      case ControlBlendMode.multiply:
        return 'Multiply';
      case ControlBlendMode.difference:
        return 'Difference';
      case ControlBlendMode.exclusion:
        return 'Exclusion';
      case ControlBlendMode.negation:
        return 'Negation';
      case ControlBlendMode.luma:
        return 'Luma';
      case ControlBlendMode.lumaAdd:
        return 'Luma Add';
      case ControlBlendMode.lumaSubtract:
        return 'Luma Subtract';
      case ControlBlendMode.lumaMultiply:
        return 'Luma Multiply';
      case ControlBlendMode.screen:
        return 'Screen';
      case ControlBlendMode.overlay:
        return 'Overlay';
      case ControlBlendMode.darken:
        return 'Darken';
      case ControlBlendMode.lighten:
        return 'Lighten';
      case ControlBlendMode.colorDodge:
        return 'Color Dodge';
      case ControlBlendMode.colorBurn:
        return 'Color Burn';
      case ControlBlendMode.hardLight:
        return 'Hard Light';
      case ControlBlendMode.softLight:
        return 'Soft Light';
      case ControlBlendMode.linearLight:
        return 'Linear Light';
      case ControlBlendMode.linearBurn:
        return 'Linear Burn';
      case ControlBlendMode.glow:
        return 'Glow';
      case ControlBlendMode.phoenix:
        return 'Phoenix';
      case ControlBlendMode.reflect:
        return 'Reflect';
    }
  }

  bool get isLuma {
    switch (this) {
      case ControlBlendMode.luma:
      case ControlBlendMode.lumaAdd:
      case ControlBlendMode.lumaSubtract:
      case ControlBlendMode.lumaMultiply:
        return true;
      default:
        return false;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AnalogSourceControlExtension on AnalogSourceControl {
  String id(String sourceId) =>
      'AnalogSource.$sourceId.AnalogSourceControl.$self';
  String get self => toString().split('.').last;
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AnalogControlExtension on AnalogControl {
  String get self => toString().split('.').last;
  String get id => 'AnalogControl.$self';
  String get name {
    switch (this) {
      case AnalogControl.zoom:
        return 'Zoom';
      case AnalogControl.blur:
        return 'Blur';
      case AnalogControl.hue:
        return 'Hue';
      case AnalogControl.saturation:
        return 'Sat';
      case AnalogControl.brightness:
        return 'Bright';
      case AnalogControl.white:
        return 'White';
    }
  }

  ControlType get type {
    switch (this) {
      case AnalogControl.zoom:
        return ControlType.float;
      case AnalogControl.blur:
        return ControlType.unit;
      case AnalogControl.hue:
        return ControlType.float;
      case AnalogControl.saturation:
        return ControlType.float;
      case AnalogControl.brightness:
        return ControlType.float;
      case AnalogControl.white:
        return ControlType.float;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CameraControlExtension on CameraControl {
  String get self => toString().split('.').last;
  String get id => 'CameraControl.$self';
  String get name {
    switch (this) {
      case CameraControl.asset:
        return 'Camera';
    }
  }

  ControlType get type {
    switch (this) {
      case CameraControl.asset:
        return ControlType.integer;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension FxControlExtension on FxControl {
  String get self => toString().split('.').last;
  String get id => 'FxControl.$self';
  String get name {
    switch (this) {
      case FxControl.asset:
        return 'Fx';
      case FxControl.level:
        return 'Level';
    }
  }

  ControlType get type {
    switch (this) {
      case FxControl.asset:
        return ControlType.integer;
      case FxControl.level:
        return ControlType.unit;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension LutControlExtension on LutControl {
  String get self => toString().split('.').last;
  String get id => 'LutControl.$self';
  String get name {
    switch (this) {
      case LutControl.asset:
        return 'LUT';
      case LutControl.fade:
        return 'Fade';
      case LutControl.intensity:
        return 'Intensity';
    }
  }

  ControlType get type {
    switch (this) {
      case LutControl.asset:
        return ControlType.integer;
      case LutControl.fade:
        return ControlType.unit;
      case LutControl.intensity:
        return ControlType.unit;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension PlayerControlExtension on PlayerControl {
  String get self => toString().split('.').last;
  String get id => 'PlayerControl.$self';
  String get name {
    switch (this) {
      case PlayerControl.position:
        return 'Position';
      case PlayerControl.asset:
        return 'Video';
    }
  }

  ControlType get type {
    switch (this) {
      case PlayerControl.position:
        return ControlType.unit;
      case PlayerControl.asset:
        return ControlType.integer;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ShaderControlExtension on ShaderControl {
  String get self => toString().split('.').last;
  String get id => 'ShaderControl.$self';
  String get name {
    switch (this) {
      case ShaderControl.asset:
        return 'Shader';
    }
  }

  ControlType get type {
    switch (this) {
      case ShaderControl.asset:
        return ControlType.integer;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension SynControlExtension on SynControl {
  String get self => toString().split('.').last;
  String get id => 'SynControl.$self';
  String get name {
    switch (this) {
      case SynControl.asset:
        return 'Syn';
    }
  }

  ControlType get type {
    switch (this) {
      case SynControl.asset:
        return ControlType.integer;
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ModuleTypeExtension on ModuleType {
  String get name {
    switch (this) {
      case ModuleType.analog:
        return 'Analog';
      case ModuleType.camera:
        return 'Camera';
      case ModuleType.fx:
        return 'Fx';
      case ModuleType.lut:
        return 'Lut';
      case ModuleType.player:
        return 'Player';
      case ModuleType.shader:
        return 'Shader';
      case ModuleType.syn:
        return 'Syn';
    }
  }

  bool get hasInput {
    switch (this) {
      case ModuleType.analog:
        return true;
      case ModuleType.camera:
        return false;
      case ModuleType.fx:
        return false;
      case ModuleType.lut:
        return true;
      case ModuleType.player:
        return false;
      case ModuleType.shader:
        return false;
      case ModuleType.syn:
        return false;
    }
  }

  List<Control> controls(String moduleId) {
    switch (this) {
      case ModuleType.analog:
        return [
          ...AnalogControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.camera:
        return [
          ...CameraControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.fx:
        return [
          ...FxControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.lut:
        return [
          ...LutControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.player:
        return [
          ...PlayerControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.shader:
        return [
          ...ShaderControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
      case ModuleType.syn:
        return [
          ...SynControl.values.map((c) => Control(
                id: c.id,
                moduleId: moduleId,
                type: c.type,
                name: c.name,
                value: 0,
                count: 0,
              ))
        ];
    }
  }

  List<Asset> assets(String moduleId) {
    switch (this) {
      case ModuleType.lut:
        return [Asset(id: 'lut.normal', name: 'Normal')];
      default:
        return [];
    }
  }

  Module create() {
    final id = const Uuid().v4();
    return Module(
        id: id,
        name: name,
        type: this,
        controls: controls(id),
        assets: assets(id));
  }

  String toJson() => toString().split('.').last;

  static ModuleType fromJson(String json) => ModuleType.values.firstWhere(
      (element) => element.toString().split('.').last == json,
      orElse: () => ModuleType.camera);
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ModuleExtension on Module {
  void upgrade() {
    final cc = type.controls(id);
    for (final c in cc) {
      final control = controls?.isEmpty ?? true
          ? null
          : controls?.firstWhereOrNull((oc) => oc?.id == c.id);
      if (control == null) {
        controls?.add(c);
      }
    }
  }

  Module copyWith(
      {String? name, List<Control?>? controls, List<Asset?>? assets}) {
    return Module(
        id: id,
        name: name ?? this.name,
        type: type,
        controls: controls ?? this.controls,
        assets: assets ?? this.assets);
  }

  bool equals(Module other) {
    final basic = id == other.id &&
        name == other.name &&
        type == other.type &&
        controls?.length == other.controls?.length &&
        assets?.length == other.assets?.length;
    if (!basic) return false;
    for (final control in (controls ?? []).whereType<Control>()) {
      final otherControl = other.controls
          ?.firstWhere((c) => c?.id == control.id, orElse: () => null);
      if (otherControl == null || !control.equals(otherControl)) {
        return false;
      }
    }
    for (final asset in (assets ?? []).whereType<Asset>()) {
      final otherAsset = other.assets
          ?.firstWhere((a) => a?.id == asset.id, orElse: () => null);
      if (otherAsset == null || !asset.equals(otherAsset)) {
        return false;
      }
    }
    return true;
  }

  Control? getControl(String id) {
    return controls!.whereType<Control>().firstWhereOrNull((c) => c.id == id);
  }

  Control operator [](String id) {
    return controls!.whereType<Control>().firstWhere((c) => c.id == id);
  }

  void operator []=(String id, Control control) {
    final index = controls!.indexWhere((c) => c?.id == id);
    controls![index] = control;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toJson(),
      'controls': controls?.map((c) => c?.toJson()).toList(),
      'assets': assets?.map((a) => a?.toJson()).toList(),
    };
  }

  static Module fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      name: json['name'],
      type: ModuleTypeExtension.fromJson(json['type']),
      controls: [...json['controls'].map((c) => ControlExtension.fromJson(c))],
      assets: [...json['assets'].map((a) => AssetExtension.fromJson(a))],
    );
  }

  List<ControlState> getControlStates() {
    if (controls != null) {
      return [...controls!.whereType<Control>().map((c) => c.state)];
    }
    return [];
  }

  List<Control> setControlStates(List<ControlState> cs) {
    List<Control> controls = [];
    for (final s in cs) {
      final c = getControl(s.id);
      if (c == null) continue;
      if (c.state == s) continue;
      c.state = s;
      controls.add(c);
    }
    return controls;
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ControlTypeExtension on ControlType {
  String toJson() => toString().split('.').last;
  static ControlType fromJson(String json) => ControlType.values.firstWhere(
      (element) => element.toString().split('.').last == json,
      orElse: () => ControlType.integer);
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ControlExtension on Control {
  Control copyWith({String? name, double? value, int? count}) {
    return Control(
      id: id,
      moduleId: moduleId,
      type: type,
      name: name ?? this.name,
      value: value ?? this.value,
      count: count ?? this.count,
    );
  }

  bool equals(Control? other) {
    if (other == null) return false;
    return id == other.id && moduleId == other.moduleId && type == other.type;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'type': type.toJson(),
      'name': name,
      'value': value,
      'count': count,
    };
  }

  static Control fromJson(Map<String, dynamic> json) {
    return Control(
      id: json['id'],
      moduleId: json['moduleId'],
      type: ControlTypeExtension.fromJson(json['type']),
      name: json['name'],
      value: json['value'],
      count: json['count'],
    );
  }

  ControlState get state => ControlState(id: id, value: value, count: count);
  set state(ControlState cValue) {
    if (cValue.id != id) throw Exception('ControlState id mismatch');
    value = cValue.value;
    count = cValue.count;
  }

  Color get color => Color(count);
  set color(Color color) => count = color.toARGB32();
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class ControlState {
  final String id;
  final double value;
  final int count;
  const ControlState({
    required this.id,
    required this.value,
    required this.count,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'count': count,
    };
  }

  factory ControlState.fromJson(Map<String, dynamic> map) {
    return ControlState(
      id: map['id'] ?? '',
      value: map['value']?.toDouble() ?? 0.0,
      count: map['count']?.toInt() ?? 0,
    );
  }
}

// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AssetExtension on Asset {
  Asset copyWith({String? name, String? uri}) {
    return Asset(id: id, name: name ?? this.name, uri: uri ?? this.uri);
  }

  bool equals(Asset other) {
    return id == other.id && name == other.name && uri == other.uri;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'uri': uri};
  }

  static Asset fromJson(Map<String, dynamic> json) {
    return Asset(id: json['id'], name: json['name'], uri: json['uri']);
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CameraDeviceExtension on CameraDevice {
  bool equals(CameraDevice other) {
    return id == other.id;
  }

  Asset toAsset() => Asset(id: id, name: name);
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension PreviewExtension on mess.Preview {
  PreviewInfo get info => PreviewInfo(
        moduleId: moduleId,
        assetId: assetId,
        //  width: width,
        //  height: height,
      );
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class PreviewInfo {
  String moduleId;
  String? assetId;
  //int width;
  //int height;
  PreviewInfo({required this.moduleId, this.assetId
      //required this.width,
      //required this.height,
      });
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
