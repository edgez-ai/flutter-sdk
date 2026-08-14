import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

enum GemmaVoiceTranslatorStatus {
  unsupported,
  missing,
  downloading,
  ready,
  translating,
  error,
}

class GemmaVoiceTranslation {
  const GemmaVoiceTranslation({
    required this.transcript,
    required this.translation,
    required this.targetLanguage,
  });

  final String transcript;
  final String translation;
  final String targetLanguage;
}

/// Android-only, fully local voice translation modeled after
/// google-gemma/gemma-translator.
///
/// Gemma 4 handles both transcription and translation in one multimodal turn.
/// This avoids shipping the reference project's Linux/Python server while
/// retaining its offline behavior after the one-time model download.
class GemmaVoiceTranslator extends ChangeNotifier {
  static const modelFileName = 'gemma-4-E2B-it.litertlm';
  static const modelUrl = 'https://huggingface.co/litert-community/'
      'gemma-4-E2B-it-litert-lm/resolve/main/$modelFileName';

  GemmaVoiceTranslatorStatus status = Platform.isAndroid
      ? GemmaVoiceTranslatorStatus.missing
      : GemmaVoiceTranslatorStatus.unsupported;
  int downloadProgress = 0;
  String errorMessage = '';
  InferenceModel? _model;
  Future<void>? _installFuture;

  bool get isSupported => status != GemmaVoiceTranslatorStatus.unsupported;
  bool get isInstalled =>
      status == GemmaVoiceTranslatorStatus.ready ||
      status == GemmaVoiceTranslatorStatus.translating;

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      final models = await FlutterGemma.listInstalledModels();
      status = models.any((name) => name.endsWith(modelFileName))
          ? GemmaVoiceTranslatorStatus.ready
          : GemmaVoiceTranslatorStatus.missing;
    } catch (error) {
      status = GemmaVoiceTranslatorStatus.error;
      errorMessage = '$error';
    }
    notifyListeners();
  }

  Future<void> install() {
    if (!Platform.isAndroid) return Future<void>.value();
    final activeInstall = _installFuture;
    if (activeInstall != null) return activeInstall;
    final future = _install();
    _installFuture = future;
    return future.whenComplete(() => _installFuture = null);
  }

  Future<void> _install() async {
    status = GemmaVoiceTranslatorStatus.downloading;
    downloadProgress = 0;
    errorMessage = '';
    notifyListeners();
    try {
      await _installModel(foreground: true);
      status = GemmaVoiceTranslatorStatus.ready;
    } catch (error) {
      status = GemmaVoiceTranslatorStatus.error;
      errorMessage = '$error';
    }
    notifyListeners();
  }

  Future<GemmaVoiceTranslation> translate({
    required EdgezMeshSdk sdk,
    required EdgezConversationMessage message,
    required String targetLanguage,
  }) async {
    if (!isInstalled) {
      throw StateError('Install Gemma 4 before translating voice messages');
    }
    status = GemmaVoiceTranslatorStatus.translating;
    errorMessage = '';
    notifyListeners();
    try {
      final model = await _activateModel(download: false);
      final wav = await sdk.decodeVoiceMessageToWav(message);
      final chat = await model.createChat(
        temperature: 0.8,
        topK: 1,
        tokenBuffer: 256,
        supportAudio: true,
        maxOutputTokens: 256,
        systemInstruction:
            'You are a high-performance voice translator. Return only valid JSON.',
      );
      try {
        await chat.addQueryChunk(
          Message.withAudio(
            text:
                'Listen to this voice message. Transcribe its original speech '
                'and translate it naturally into $targetLanguage. Return exactly '
                '{"transcript":"original words","translation":"translated words"} '
                'with no Markdown or commentary.',
            audioBytes: wav,
            isUser: true,
          ),
        );
        final response = await chat.generateChatResponse();
        if (response is! TextResponse) {
          throw StateError('Gemma returned an unexpected response');
        }
        return _parseResponse(response.token, targetLanguage);
      } finally {
        await chat.close();
      }
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      status = GemmaVoiceTranslatorStatus.ready;
      notifyListeners();
    }
  }

  Future<InferenceModel> _activateModel({required bool download}) async {
    if (_model != null) return _model!;
    await _installModel(foreground: download);
    _model = await FlutterGemma.getActiveModel(
      // Gemma 4 E2B is close to the memory limit on mid-range Android
      // devices such as the Samsung A23. A 1024-token context is LiteRT-LM's
      // supported minimum and avoids the much larger 2048-token KV cache.
      // CPU also avoids keeping a second GPU-side copy of model buffers.
      maxTokens: 1024,
      preferredBackend: PreferredBackend.cpu,
      supportAudio: true,
      enableSpeculativeDecoding: false,
      maxConcurrentSessions: 1,
    );
    return _model!;
  }

  Future<void> _installModel({required bool foreground}) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(modelUrl, foreground: foreground).withProgress((progress) {
      downloadProgress = progress;
      notifyListeners();
    }).install();
  }

  GemmaVoiceTranslation _parseResponse(String raw, String targetLanguage) {
    var value = raw.trim();
    if (value.startsWith('```json')) value = value.substring(7);
    if (value.startsWith('```')) value = value.substring(3);
    if (value.endsWith('```')) value = value.substring(0, value.length - 3);
    value = value.trim();
    try {
      final json = jsonDecode(value);
      if (json is Map) {
        final transcript = '${json['transcript'] ?? ''}'.trim();
        final translation = '${json['translation'] ?? ''}'.trim();
        if (translation.isNotEmpty) {
          return GemmaVoiceTranslation(
            transcript: transcript,
            translation: translation,
            targetLanguage: targetLanguage,
          );
        }
      }
    } catch (_) {
      // A useful plain-text translation is preferable to discarding a model
      // response solely because it missed the requested JSON envelope.
    }
    if (value.isEmpty) throw StateError('Gemma returned an empty translation');
    return GemmaVoiceTranslation(
      transcript: '',
      translation: value,
      targetLanguage: targetLanguage,
    );
  }

  @override
  void dispose() {
    final model = _model;
    _model = null;
    if (model != null) unawaited(model.close());
    super.dispose();
  }
}
