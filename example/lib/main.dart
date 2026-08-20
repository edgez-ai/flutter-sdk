import 'dart:io';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialConfiguration = await EdgezBleConfigurationStore().load();
  if (Platform.isAndroid) {
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
    );
  }
  runApp(EdgezExampleApp(initialConfiguration: initialConfiguration));
}
