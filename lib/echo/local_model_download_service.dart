import 'dart:async';
import 'dart:io';

import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class EchoModelOption {
  final String id;
  final String name;
  final String subtitle;
  final String size;
  final String fileName;
  final String url;
  final bool recommended;

  const EchoModelOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.size,
    required this.fileName,
    required this.url,
    this.recommended = false,
  });
}

const echoModelCatalog = [
  EchoModelOption(
    id: 'qwen3_06b',
    name: 'Qwen3 0.6B',
    subtitle: 'Best for emulator testing. Small, public, Apache 2.0.',
    size: '614 MB',
    fileName: 'Qwen3-0.6B.litertlm',
    url: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm?download=true',
    recommended: true,
  ),
  EchoModelOption(
    id: 'gemma4_e2b',
    name: 'Gemma 4 E2B',
    subtitle: 'Primary Echo offline model. Better quality, larger download.',
    size: '2.58 GB',
    fileName: 'gemma-4-E2B-it.litertlm',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true',
  ),
  EchoModelOption(
    id: 'gemma4_e4b',
    name: 'Gemma 4 E4B',
    subtitle: 'Heavier Gemma option for strong devices with enough storage.',
    size: '3.66 GB',
    fileName: 'gemma-4-E4B-it.litertlm',
    url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm?download=true',
  ),
];

class LocalModelDownloadService extends ChangeNotifier {
  LocalModelDownloadService._();
  static final LocalModelDownloadService _instance = LocalModelDownloadService._();
  factory LocalModelDownloadService() => _instance;

  http.Client? _client;
  EchoModelOption? _activeModel;
  double? _progress;
  String? _error;
  bool _downloading = false;

  EchoModelOption? get activeModel => _activeModel;
  double? get progress => _progress;
  String? get error => _error;
  bool get downloading => _downloading;
  String? get activeModelId => _activeModel?.id;

  Future<void> download(EchoModelOption model) async {
    if (_downloading) return;

    _activeModel = model;
    _progress = null;
    _error = null;
    _downloading = true;
    notifyListeners();

    final client = http.Client();
    _client = client;

    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${baseDir.path}${Platform.pathSeparator}echo_models');
      if (!await modelDir.exists()) await modelDir.create(recursive: true);
      final destination = File('${modelDir.path}${Platform.pathSeparator}${model.fileName}');
      final partial = File('${destination.path}.part');
      if (await partial.exists()) await partial.delete();

      final request = http.Request('GET', Uri.parse(model.url));
      request.followRedirects = true;
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with HTTP ${response.statusCode}');
      }

      final total = response.contentLength;
      var received = 0;
      var lastNotify = DateTime.now();
      final sink = partial.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total != null && total > 0) {
          _progress = received / total;
          final now = DateTime.now();
          if (now.difference(lastNotify).inMilliseconds > 250) {
            lastNotify = now;
            notifyListeners();
          }
        }
      }
      await sink.flush();
      await sink.close();

      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);

      await EchoRuntimeService().setDeviceModel(path: destination.path, version: model.name);
      await EchoRuntimeService().setMode(EchoRuntimeMode.device);
      _progress = 1.0;
    } catch (e) {
      _error = e.toString().contains('ClientException') ? 'Download stopped.' : 'Could not download ${model.name}: $e';
    } finally {
      if (identical(_client, client)) _client = null;
      client.close();
      _downloading = false;
      _activeModel = null;
      notifyListeners();
    }
  }

  void stop() {
    _client?.close();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
