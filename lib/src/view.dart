import 'package:bb.flutter/bb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class AlibView extends StatefulWidget {
  final String moduleId;
  final String? assetId;
  final Color color;
  final double gain;
  final bool paused;
  const AlibView(
      {super.key,
      required this.moduleId,
      this.assetId,
      this.color = Colors.white,
      this.gain = 1.0,
      this.paused = false});
  @override
  State<AlibView> createState() => _AlibViewState();
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
class _AlibViewState extends State<AlibView> {
  MethodChannel? platformChannel;
  @override
  void didUpdateWidget(covariant AlibView oldWidget) {
    if (oldWidget.paused != widget.paused ||
        oldWidget.moduleId != widget.moduleId ||
        oldWidget.assetId != widget.assetId ||
        oldWidget.color != widget.color) {
      platformChannel?.invokeMethod('updateView', params);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AppKitView(
      onPlatformViewCreated: (int viewId) {
        platformChannel = MethodChannel('aestesis/alibview_macos_$viewId');
      },
      viewType: "@views/alibview-view-type",
      layoutDirection: TextDirection.ltr,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Map<String, dynamic> get params => <String, dynamic>{
        'moduleId': widget.moduleId,
        if (widget.assetId != null) 'assetId': widget.assetId,
        'color': widget.color.toHex(),
        'gain': widget.gain,
        'pause': widget.paused ? 'pause' : 'resume'
      };
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
