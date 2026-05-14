import 'dart:async';

import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LocalGemmaStatus {
  final bool supported;
  final bool ready;
  final String? modelPath;
  final String? message;

  const LocalGemmaStatus({required this.supported, required this.ready, this.modelPath, this.message});

  factory LocalGemmaStatus.fromMap(Map<dynamic, dynamic> data) {
    return LocalGemmaStatus(
      supported: data['supported'] == true,
      ready: data['ready'] == true,
      modelPath: data['modelPath'] as String?,
      message: data['message'] as String?,
    );
  }
}

class LocalGemmaService {
  LocalGemmaService._();
  static final LocalGemmaService _instance = LocalGemmaService._();
  factory LocalGemmaService() => _instance;

  static const MethodChannel _channel = MethodChannel('echo.local_gemma');

  Future<LocalGemmaStatus> status() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const LocalGemmaStatus(supported: false, ready: false, message: 'Offline Echo is Android-first in this build.');
    }

    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('status');
      if (result != null) {
        final native = LocalGemmaStatus.fromMap(result);
        final runtime = EchoRuntimeService();
        if (!native.ready && runtime.isDeviceReady) {
          return LocalGemmaStatus(
            supported: native.supported,
            ready: true,
            modelPath: runtime.deviceModelPath,
            message: 'Offline model is configured and will load on first use.',
          );
        }
        return native;
      }
    } on MissingPluginException {
      return _statusFromRuntime(message: 'Offline Echo is not installed on this build yet.');
    } catch (e) {
      return LocalGemmaStatus(supported: true, ready: false, message: e.toString());
    }

    return _statusFromRuntime();
  }

  Future<void> loadModel() async {
    final runtime = EchoRuntimeService();
    if (!runtime.isDeviceReady) {
      throw StateError('No on-device model is configured.');
    }
    await _channel.invokeMethod<void>('loadModel', {'modelPath': runtime.deviceModelPath});
  }

  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (_) {
      // Best effort. The native bridge may not exist yet.
    }
  }

  Stream<String> generate({required String prompt, int maxTokens = 512, double temperature = 0.7}) async* {
    final runtime = EchoRuntimeService();
    if (!runtime.isDeviceReady) {
      yield 'Offline Echo is not ready yet. Open Where Echo Thinks and import an offline model before using Talk without Wi-Fi.';
      return;
    }

    try {
      final text = await _channel.invokeMethod<String>('generate', {
        'modelPath': runtime.deviceModelPath,
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      final output = text?.trim();
      if (output == null || output.isEmpty) {
        yield 'The local model returned an empty response.';
      } else {
        yield output;
      }
    } on MissingPluginException {
      yield 'This phone is set to This Device mode, but Offline Echo is not installed in this build yet. Echo saved the runtime choice.';
    } catch (e) {
      yield 'Offline Echo failed to respond: $e';
    }
  }

  LocalGemmaStatus _statusFromRuntime({String? message}) {
    final runtime = EchoRuntimeService();
    return LocalGemmaStatus(
      supported: defaultTargetPlatform == TargetPlatform.android,
      ready: runtime.isDeviceReady,
      modelPath: runtime.deviceModelPath,
      message: message,
    );
  }
}
