import 'package:bb_dart/bb_dart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:aestesis_engine/aestesis_engine.dart';

final aestesis = AestesisEngine();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    //initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final composition = await aestesis.composition();
    Debug.info('composition: ${composition.id}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(child: Text('plop')),
      ),
    );
  }
}
