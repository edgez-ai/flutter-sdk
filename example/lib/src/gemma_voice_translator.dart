import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
/// Gemma 4 performs one offline transcript, which is stored on the message.
/// Later translations use only that saved text and never process audio again.
class GemmaVoiceTranslator extends ChangeNotifier {
  static const _ttsChannel = MethodChannel(
    'ai.edgez.flutter_sdk_example/text_to_speech',
  );
  static const modelFileName = 'gemma-4-E2B-it.litertlm';
  static const modelUrl = 'https://huggingface.co/litert-community/'
      'gemma-4-E2B-it-litert-lm/resolve/main/$modelFileName';

  GemmaVoiceTranslator() {
    if (Platform.isAndroid) {
      _ttsChannel.setMethodCallHandler(_handleSpeechMethod);
    }
  }

  GemmaVoiceTranslatorStatus status = Platform.isAndroid
      ? GemmaVoiceTranslatorStatus.missing
      : GemmaVoiceTranslatorStatus.unsupported;
  int downloadProgress = 0;
  int speechDownloadProgress = 0;
  bool preparingSpeech = false;
  String speechDownloadFile = '';
  String errorMessage = '';
  InferenceModel? _model;
  bool _modelSupportsAudio = false;
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
    required String sourceLanguage,
    required String targetLanguage,
    FutureOr<void> Function(String transcript, String language)? onTranscript,
  }) async {
    if (!isInstalled) {
      throw StateError('Install Gemma 4 before translating voice messages');
    }
    status = GemmaVoiceTranslatorStatus.translating;
    errorMessage = '';
    notifyListeners();
    try {
      if (message.transcript.trim().isNotEmpty) {
        return await _translateTranscript(
          transcript: message.transcript.trim(),
          sourceLanguage: message.transcriptLanguage.isEmpty
              ? sourceLanguage
              : message.transcriptLanguage,
          targetLanguage: targetLanguage,
        );
      }
      return await _transcribeAndTranslate(
        sdk: sdk,
        message: message,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        onTranscript: onTranscript,
      );
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      status = GemmaVoiceTranslatorStatus.ready;
      notifyListeners();
    }
  }

  Future<GemmaVoiceTranslation> _transcribeAndTranslate({
    required EdgezMeshSdk sdk,
    required EdgezConversationMessage message,
    required String sourceLanguage,
    required String targetLanguage,
    FutureOr<void> Function(String transcript, String language)? onTranscript,
  }) async {
    // Keep transcription and translation in separate model lifetimes. The
    // audio-capable engine is released as soon as the reusable transcript is
    // available; translation then reloads Gemma without its audio encoder.
    await _releaseInferenceModel();
    final wav = await sdk.decodeVoiceMessageToWav(message);
    final model = await _activateModel(download: false, supportAudio: true);
    final chat = await model.createChat(
      temperature: 0.1,
      topK: 1,
      tokenBuffer: 32,
      supportAudio: true,
      maxOutputTokens: 64,
      systemInstruction: 'The audio language is $sourceLanguage. Transcribe '
          'it only as $sourceLanguage; do not detect or translate languages. '
          'Return only JSON: {"transcript":"speech"}. Add natural '
          'punctuation supported by the language. Never add instructions, '
          'labels, or words that were not spoken.',
    );
    String transcript;
    try {
      await chat.addQueryChunk(
        Message.withAudio(
          text: 'Transcribe this $sourceLanguage audio using the required '
              'JSON format.',
          audioBytes: wav,
          isUser: true,
        ),
      );
      final response = await chat.generateChatResponse();
      if (response is! TextResponse) {
        throw StateError('Gemma returned an unexpected transcript response');
      }
      transcript = _parseTranscript(response.token);
    } finally {
      await chat.close();
      await _releaseInferenceModel();
    }
    await onTranscript?.call(transcript, sourceLanguage);
    return _translateTranscript(
      transcript: transcript,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  Future<GemmaVoiceTranslation> _translateTranscript({
    required String transcript,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (sourceLanguage == targetLanguage) {
      return GemmaVoiceTranslation(
        transcript: transcript,
        translation: transcript,
        targetLanguage: targetLanguage,
      );
    }
    final model = await _activateModel(download: false, supportAudio: false);
    final chat = await model.createChat(
      temperature: 0.2,
      topK: 1,
      tokenBuffer: 128,
      maxOutputTokens: 96,
      systemInstruction:
          'Translate the user text from $sourceLanguage into $targetLanguage. '
          'Return only JSON: {"translation":"translation"}. Use natural '
          'punctuation for clear TTS. Do not add, omit, or explain content.',
    );
    try {
      await chat.addQueryChunk(Message.text(text: transcript, isUser: true));
      final response = await chat.generateChatResponse();
      if (response is! TextResponse) {
        throw StateError('Gemma returned an unexpected response');
      }
      final parsed = _parseResponse(response.token, targetLanguage);
      return GemmaVoiceTranslation(
        transcript: transcript,
        translation: parsed.translation,
        targetLanguage: targetLanguage,
      );
    } finally {
      await chat.close();
    }
  }

  /// Speaks a translated result with the same Moonshine Voice Kokoro/Piper
  /// pipeline used by google-gemma/gemma-translator.
  Future<void> speak(GemmaVoiceTranslation translation) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Translation speech is Android-only');
    }
    preparingSpeech = true;
    speechDownloadProgress = 0;
    speechDownloadFile = '';
    notifyListeners();
    try {
      // Gemma 4 and Moonshine each need a large native runtime. Mid-range
      // phones cannot reliably hold both at once, so hand memory over to TTS
      // before Moonshine loads its voice model.
      await _releaseInferenceModel();
      await _ttsChannel.invokeMethod<void>('speak', <String, String>{
        'text': translation.translation,
        'languageTag': _ttsLanguageTags[translation.targetLanguage] ?? 'en-us',
      });
    } finally {
      preparingSpeech = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    if (!Platform.isAndroid) return;
    await _ttsChannel.invokeMethod<void>('stop');
  }

  Future<void> _handleSpeechMethod(MethodCall call) async {
    if (call.method != 'progress') return;
    final arguments = call.arguments;
    if (arguments is! Map) return;
    speechDownloadProgress = (arguments['percent'] as num?)?.round() ?? 0;
    speechDownloadFile = '${arguments['file'] ?? ''}';
    notifyListeners();
  }

  Future<InferenceModel> _activateModel({
    required bool download,
    required bool supportAudio,
  }) async {
    if (_model != null && _modelSupportsAudio == supportAudio) return _model!;
    if (_model != null) await _releaseInferenceModel();
    // Stop speech and release Moonshine's ONNX session before LiteRT-LM maps
    // Gemma back into memory. Downloaded voice assets remain cached on disk.
    if (Platform.isAndroid) {
      await _ttsChannel.invokeMethod<void>('release');
    }
    await _installModel(foreground: download);
    _model = await FlutterGemma.getActiveModel(
      // Gemma 4 E2B is close to the memory limit on mid-range Android
      // devices such as the Samsung A23. A 1024-token context is LiteRT-LM's
      // supported minimum and avoids the much larger 2048-token KV cache.
      // CPU also avoids keeping a second GPU-side copy of model buffers.
      maxTokens: 1024,
      preferredBackend: PreferredBackend.cpu,
      supportAudio: supportAudio,
      enableSpeculativeDecoding: false,
      maxConcurrentSessions: 1,
    );
    _modelSupportsAudio = supportAudio;
    return _model!;
  }

  Future<void> _releaseInferenceModel() async {
    final model = _model;
    _model = null;
    _modelSupportsAudio = false;
    if (model != null) await model.close();
  }

  String _parseTranscript(String raw) {
    var value = raw.trim();
    if (value.startsWith('```json')) value = value.substring(7);
    if (value.startsWith('```')) value = value.substring(3);
    if (value.endsWith('```')) value = value.substring(0, value.length - 3);
    value = value.trim();
    final candidates = <String>[
      value,
      ...RegExp(r'\{[^{}]*\}', dotAll: true)
          .allMatches(value)
          .map((match) => match.group(0)!),
    ];
    for (final candidate in candidates.reversed) {
      try {
        final json = jsonDecode(candidate);
        if (json is Map) {
          final transcript = _stripInstructionEcho(
            '${json['transcript'] ?? ''}',
          );
          if (transcript.isNotEmpty) return transcript;
        }
      } catch (_) {
        // Try the next structured candidate, then the plain-text fallback.
      }
    }
    final transcript = _stripInstructionEcho(value);
    if (transcript.isEmpty) {
      throw StateError('Gemma returned an empty transcript');
    }
    return transcript;
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

    final exactJson = _tryParseJsonTranslation(value, targetLanguage);
    if (exactJson != null) return exactJson;

    // Gemma sometimes prefixes its JSON with a plain-text translation. Pull
    // out the structured object instead of displaying both copies to users.
    final jsonObjects = RegExp(r'\{[^{}]*\}', dotAll: true)
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toList();
    for (final candidate in jsonObjects.reversed) {
      final embeddedJson = _tryParseJsonTranslation(candidate, targetLanguage);
      if (embeddedJson != null) return embeddedJson;
    }

    // A useful plain-text translation is preferable to discarding a model
    // response solely because it missed the requested JSON envelope.
    value = _stripInstructionEcho(value);
    if (value.isEmpty) throw StateError('Gemma returned an empty translation');
    return GemmaVoiceTranslation(
      transcript: '',
      translation: value,
      targetLanguage: targetLanguage,
    );
  }

  GemmaVoiceTranslation? _tryParseJsonTranslation(
    String value,
    String targetLanguage,
  ) {
    try {
      final json = jsonDecode(value);
      if (json is! Map) return null;
      final transcript = _stripInstructionEcho(
        '${json['transcript'] ?? ''}'.trim(),
      );
      final translation = _stripInstructionEcho(
        '${json['translation'] ?? ''}'.trim(),
      );
      if (translation.isEmpty) return null;
      return GemmaVoiceTranslation(
        transcript: transcript,
        translation: translation,
        targetLanguage: targetLanguage,
      );
    } catch (_) {
      return null;
    }
  }

  String _stripInstructionEcho(String value) {
    var cleaned = value.trim();
    final instructionSuffixes = <RegExp>[
      RegExp(
        r'(?:[.!?]\s*)?(?:listen to|read|translate|transcribe) '
        r'(?:this |the )?(?:voice )?message[.!?]*$',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:[.!?]\s*)?target\s*=\s*'
        r'(?:arabic|chinese|english|japanese|korean|spanish)[.!?]*$',
        caseSensitive: false,
      ),
    ];
    var changed = true;
    while (changed) {
      changed = false;
      for (final suffix in instructionSuffixes) {
        if (suffix.hasMatch(cleaned)) {
          cleaned = cleaned.replaceFirst(suffix, '').trimRight();
          changed = true;
        }
      }
    }
    return cleaned;
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _ttsChannel.setMethodCallHandler(null);
      unawaited(stopSpeaking());
    }
    unawaited(_releaseInferenceModel());
    super.dispose();
  }
}

const _ttsLanguageTags = <String, String>{
  'Arabic': 'ar-msa',
  'Chinese': 'zh-hans',
  'English': 'en-us',
  'Japanese': 'ja-jp',
  'Korean': 'ko-kr',
  'Spanish': 'es-es',
};

const supportedVoiceTranslationLanguages = <String>[
  'Arabic',
  'Chinese',
  'English',
  'Japanese',
  'Korean',
  'Spanish',
];
