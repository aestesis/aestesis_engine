import 'dart:async';

import 'package:bb_dart/bb_dart.dart';
import 'package:flutter/services.dart';

import 'interface/messages.g.dart';

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension MessageLevelExtension on MessageLevel {
  String get name => toString().split('.').last.capitalized;
  String get emoji {
    switch (this) {
      case MessageLevel.info:
        return 'ℹ️';
      case MessageLevel.warning:
        return '⚡';
      case MessageLevel.error:
        return '💥';
    }
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class Message {
  final MessageLevel level;
  final String text;
  Message({required this.level, required this.text});
  @override
  String toString() => '${level.emoji} >>> $text';
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AssetTextureExtension on AssetTexture {
  String get key => '$moduleId.$assetId';
  String get debugDescription {
    return 'AssetTexture(moduleId: $moduleId, assetId: $assetId, textureId: $textureId)';
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class MessageAestesisEngine extends MessageAestesisEngineApi {
  final _textureCtrl = StreamController<AssetTexture>.broadcast();
  final _previewCtrl = StreamController<Preview>.broadcast();
  final _statisticsCtrl = StreamController<CompositionStatistics>.broadcast();
  final _controlCtrl = StreamController<Control>.broadcast();
  final _audioCtrl = StreamController<AudioLevel>.broadcast();
  final _messageCtrl = StreamController<Message>.broadcast();
  final _statesCtrl = StreamController<CompositionStates>.broadcast();
  @override
  void texture(AssetTexture asset) {
    _textureCtrl.add(asset);
  }

  @override
  void preview(Preview preview) {
    _previewCtrl.add(preview);
  }

  @override
  void statistics(CompositionStatistics statistics) {
    _statisticsCtrl.add(statistics);
  }

  @override
  void control(Control control) {
    _controlCtrl.add(control);
  }

  @override
  void audio(AudioLevel level) {
    _audioCtrl.add(level);
  }

  @override
  void message(MessageLevel level, String message) {
    _messageCtrl.add(Message(level: level, text: message));
  }

  @override
  void states(CompositionStates states) {
    _statesCtrl.add(states);
  }

  StreamSubscription listenTexture(
    void Function(AssetTexture event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _textureCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenPreview(
    void Function(Preview event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _previewCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenStatistics(
    void Function(CompositionStatistics event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _statisticsCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenControl(
    void Function(Control event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _controlCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenAudio(
    void Function(AudioLevel event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _audioCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenMessage(
    void Function(Message message)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _messageCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  StreamSubscription listenStates(
    void Function(CompositionStates states)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _statesCtrl.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  MessageAestesisEngine() {
    MessageAestesisEngineApi.setUp(this);
  }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class AestesisEngine extends AestesisEngineApi {
  final message = MessageAestesisEngine();
  AestesisEngine({super.binaryMessenger, super.messageChannelSuffix = ''});
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
