# Aestesis Engine

A high-performance video composition engine for Flutter, built on Swift/Metal for macOS and iOS.

[![Platform](https://img.shields.io/badge/platform-macOS%2FiOS-blue.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-326F1B.svg)](https://flutter.dev)
[![Version](https://img.shields.io/badge/version-1.0.5-brightgreen.svg)](pubspec.yaml)

---

## 🎬 Features

- **Modular Video Pipeline** - Compose video effects using a flexible node-based system
- **Real-time Preview** - Low-latency rendering with FPS monitoring
- **Multi-Platform** - macOS and iOS support
- **Native Performance** - Swift implementation with metal/shader optimization
- **Live Streaming Ready** - Supports streaming and recording pipelines
- **Asset Management** - Built-in asset loader with JSON data storage
- **Camera Integration** - Access to built-in and external cameras
- **Audio Processing** - 3-band EQ and audio level meters

---

## 📦 Setup

### Prerequisites

- macOS 26.0+ or iOS 26.0+
- Flutter 3.3.0+
- Dart 3.10.0+
- Xcode 26+ (for iOS/macOS development)
- CocoaPods & Swift Package Manager installed

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  aestesis_engine:
    git:
      url: https://github.com/aestesis/aestesis_engine.git
```

### Dependencies

The plugin uses:

- `bb_dart` - Core video engine (git dependency)
- `bb.flutter` - Flutter integration layer
- `plugin_platform_interface` - Plugin API compatibility
- `collection`, `uuid` - Utility packages

---

## 🚀 Usage

### Basic Example

```dart
import 'package:aestesis_engine/aestesis_engine.dart';

final aestesis = AestesisEngine();

// Initialize engine and get composition
await aestesis.message.listenMessage((msg) {
  if (msg.level == MessageLevel.error) {
    print('✖️ $msg');
  }
});

final composition = await aestesis.composition();
print('Composition ID: ${composition.id}');
```

### Listen to Events

```dart
// Listen for new textures
final textureStream = aestesis.texture.listen((texture) {
  print('New texture: ${texture.debugDescription}');
});

// Listen for preview updates
final previewStream = aestesis.preview.listen((preview) {
  print('Preview: ${preview.width}x${preview.height}');
});

// Listen for statistics
final statsStream = aestesis.statistics.listen((stats) {
  print('FPS: ${stats.fps}, CPU: ${(stats.cpu * 100).toInt()}%');
  print('GPU: ${(stats.gpu * 100).toInt()}%, RAM: ${(stats.ram * 1024 * 1024 * 1024).toInt()}');
});
```

### Managing Modules

#### Add Module

```dart
final composition = composition; // Get current composition
final module = Module(
  id: 'my_module',
  type: ModuleType.analog,
  name: 'My Analog Module',
);

composition = await aestesis.addModule(module);
```

#### Insert Module at Specific Index

```dart
composition = await aestesis.insertModule(module, index: 1);
```

#### Remove Module

```dart
composition = await aestesis.removeModule('my_module');
```

#### Update Module

```dart
final updatedModule = Module(
  id: 'my_module',
  type: ModuleType.fx,
  name: 'Updated FX Module',
  controls: [
    Control(
      id: 'gain',
      name: 'Gain',
      type: ControlType.float,
      value: 0.5,
    ),
  ],
);
composition = await aestesis.updateModule(updatedModule);
```

### Adding Assets

```dart
final assets = [
  Asset(
    id: 'texture_1',
    name: 'My Texture',
    uri: 'assets/texture.png', // or data URI
  ),
];

composition = await aestesis.addAssets('my_module', assets);
```

### Updating Controls

```dart
await aestesis.updateControl(Control(
  moduleId: 'my_module',
  id: 'gain',
  name: 'Gain',
  type: ControlType.float,
  value: 0.8,
));
```

### Recording & Preview

```dart
// Enable preview output
await aestesis.outputView(show: true);

// Start recording
await aestesis.startRecording('/path/to/output.mp4');

// Listen to recording state
await aestesis.states.listen((states) {
  if (states.recording) {
    print('🎬 Recording...');
  }
});
```

### Camera Access

```dart
// Get available camera devices
final cameras = await aestesis.cameraDevices();

for (final camera in cameras) {
  print('Camera: ${camera.name} (${camera.model})');
  print('Type: ${camera.type}, Position: ${camera.position}');
}
```

### Audio Devices

```dart
final audioDevices = await aestesis.audioDevices();
for (final device in audioDevices) {
  print('Audio: ${device.name}');
  print('Output Channels: ${device.outputChannels}');
}
```

---

## 🧩 Module Types

| ModuleType | Description | Typical Use |
|------------|-------------|-------------|
| `analog` | Analog controls (zoom, blur, hue, etc.) | Color grading, effects |
| `camera` | Camera input module | Video feed from camera |
| `fx` | Visual effects module | Filters, transforms |
| `lut` | Look-up table module | Color transforms |
| `player` | Media player module | Playing video files |
| `shader` | Custom shader module | metal shaders |
| `syn` | Synthesizer module | Audio synthesis |

---

## 🎚️ Analog Controls

| Control | Range | Description |
|---------|-------|-------------|
| `zoom` | Unit | Zoom level |
| `blur` | Unit | Blur amount |
| `hue` | Float | Hue shift (-1 to 1) |
| `saturation` | Unit | Color saturation |
| `brightness` | Unit | Brightness |
| `white` | Unit | White balance |

---

## 📡 Control Types

| Type | Range | Description |
|------|-------|-------------|
| `float` | [-1, 1] or unit | Continuous values |
| `unit` | [0, 1] | Normalized values |
| `integer` | [0, ∞] | Integer values |
| `boolean` | 0/1 | On/off switch |
| `color` | 0xAARRGGBB | Hex color |

---

## 🎨 Blend Modes

The plugin supports standard blend modes including:

- `normal`, `add`, `subtract`, `multiply`, `difference`
- `screen`, `overlay`, `darken`, `lighten`
- `colorDodge`, `colorBurn`, `hardLight`, `softLight`
- `luma`, `lumaAdd`, `lumaSubtract`, `lumaMultiply`
- `phoenix`, `reflect`, `glow`

---

## 📊 Statistics

| Metric | Description |
|--------|-------------|
| `fps` | Frames per second |
| `cpu` | CPU usage (0.0-1.0) |
| `gpu` | GPU usage (0.0-1.0) |
| `ram` | Memory usage in gigabytes |

---

## 🎵 Audio

The audio subsystem provides:

- **Peak Levels** - Real-time audio level monitoring (-1.0 to 0.0)
- **3-Band EQ** - Low, mid, and high frequency adjustments
- **Multiple Devices** - Access to various audio hardware

---

## 📁 Asset Management

```dart
// Set asset data
await aestesis.setAssetData('my_texture', '{ "type": "image", "path": "@/texture.png" }');

// Get asset data
String? data = await aestesis.getAssetData('my_texture');

// Set multiple assets
await aestesis.setAssetDatas('{ "key1": "value1", "key2": "value2" }');

// Get all assets
String? allData = await aestesis.getAssetDatas();
```

---

## 📁 File Picker

```dart
final files = await aestesis.pickFiles(
  title: 'Select File',
  directory: null,
  multiple: false,
  extensions: ['jpg', 'png', 'mp4'],
);

for (final file in files) {
  print('Selected: $file');
}
```

**Note:** On iOS, this currently returns empty results as a placeholder.

---

## 🌐 Platform Specifics

### macOS

- Full Swift Package Manager support
- CocoaPods integration via SPM
- Access to system cameras and audio devices
- All features fully functional

### iOS

- Similar SwiftPM setup available
- Camera permissions required for camera access
- File picker limited to UIDocumentPicker
- Some features may have platform-specific limitations

---

## 📐 Composition Settings

```dart
final settings = CompositionSettings(
  width: 1920,
  height: 1080,
  fps: 60.0,
  audioSettings: AudioSettings(
    deviceName: 'Built-in Microphone',
    leftChannel: 1,
    rightChannel: 2,
  ),
);

await aestesis.settings(settings);
```

---

## 🎪 States

Monitor the composition state:

```dart
await aestesis.states.listen((states) {
  print('Recording: ${states.recording}');
  print('Streaming: ${states.streaming}');
  print('Previewing: ${states.previewing}');
});
```

---

## 🚨 Error Handling

The engine uses message channels for logging:

```dart
// Listen for engine messages
await aestesis.message.listenMessage((message) {
  if (message.level == MessageLevel.error) {
    print('❌ Error: ${message.text}');
  } else if (message.level == MessageLevel.warning) {
    print('⚡ Warning: ${message.text}');
  } else {
    print('ℹ️ Info: ${message.text}');
  }
});
```

---

## 🛠️ Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Camera permission denied | Request permission in UI settings |
| Preview not showing | Ensure `outputView(show: true)` is called |
| Audio levels low | Check input device and volume settings |
| FPS drops | Reduce complexity or check CPU/GPU load |

---

## 📜 License

This project is licensed under its Apache 2.0 license. See `LICENSE` file for details.

---

## 📬 Support

- **GitHub Issues**: [aestesis/aestesis_engine](https://github.com/aestesis/aestesis_engine/issues)

---

## 🔄 Changelog

### v1.0.5 (Latest)
- Latest stable release with all current features

### v0.0.1
- Initial release placeholder

---

**For more examples and detailed documentation, please check the GitHub repository:**
[https://github.com/aestesis/aestesis_engine](https://github.com/aestesis/aestesis_engine)
