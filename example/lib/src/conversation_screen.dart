import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'gemma_voice_translator.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.activeConnection,
    required this.user,
    required this.messages,
    required this.sensorSamples,
    required this.linkStats,
    required this.onBack,
    required this.onSendMessage,
    required this.onStartVoiceMessage,
    required this.onStopVoiceMessage,
    required this.onReplayVoiceMessage,
    required this.onStartSpeedTest,
    required this.callState,
    required this.onStartCall,
    required this.defaultTargetLanguage,
    this.gemmaTranslator,
    this.onTranslateVoiceMessage,
    this.onRetranscribeVoiceMessage,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshNode user;
  final List<EdgezConversationMessage> messages;
  final List<EdgezSensorSample> sensorSamples;
  final EdgezLinkStats? linkStats;
  final VoidCallback onBack;
  final Future<void> Function(String) onSendMessage;
  final Future<bool> Function() onStartVoiceMessage;
  final Future<void> Function(bool send) onStopVoiceMessage;
  final ValueChanged<EdgezConversationMessage> onReplayVoiceMessage;
  final Future<void> Function(
    int hop,
    void Function(int sentBytes, int totalBytes) onProgress,
  ) onStartSpeedTest;
  final EdgezVoiceCallState callState;
  final Future<void> Function() onStartCall;
  final String defaultTargetLanguage;
  final GemmaVoiceTranslator? gemmaTranslator;
  final Future<GemmaVoiceTranslation> Function(
    EdgezConversationMessage message,
    String targetLanguage,
  )? onTranslateVoiceMessage;
  final Future<GemmaVoiceTranslation> Function(
    EdgezConversationMessage message,
    String targetLanguage,
  )? onRetranscribeVoiceMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController controller = TextEditingController();
  String status = '';
  bool recording = false;
  bool voicePressed = false;
  bool voiceStarting = false;
  bool speedTesting = false;
  int speedTestSentBytes = 0;
  int speedTestTotalBytes = EdgezMeshSdk.speedTestBytes;
  int speedTestHop = 0;
  int speedTestStartedAtMs = 0;
  double speedTestSendBitsPerSecond = 0;
  late String translationLanguage;
  final Map<String, GemmaVoiceTranslation> translations =
      <String, GemmaVoiceTranslation>{};
  final Map<String, String> translationErrors = <String, String>{};
  final Map<String, String> speechErrors = <String, String>{};
  final Set<String> translatingMessages = <String>{};

  @override
  void initState() {
    super.initState();
    translationLanguage = widget.defaultTargetLanguage;
    widget.gemmaTranslator?.addListener(_gemmaChanged);
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gemmaTranslator != widget.gemmaTranslator) {
      oldWidget.gemmaTranslator?.removeListener(_gemmaChanged);
      widget.gemmaTranslator?.addListener(_gemmaChanged);
    }
    if (oldWidget.defaultTargetLanguage != widget.defaultTargetLanguage) {
      translationLanguage = widget.defaultTargetLanguage;
    }
  }

  void _gemmaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.gemmaTranslator?.removeListener(_gemmaChanged);
    controller.dispose();
    super.dispose();
  }

  String _messageKey(EdgezConversationMessage message) =>
      message.messageUuid.isNotEmpty
          ? message.messageUuid
          : '${message.nodeNum}:${message.timestampMs}:${message.mine}';

  Future<void> _translateVoiceMessage(EdgezConversationMessage message,
      {bool retranscribe = false}) async {
    final translate = retranscribe
        ? widget.onRetranscribeVoiceMessage
        : widget.onTranslateVoiceMessage;
    final translator = widget.gemmaTranslator;
    if (translate == null || translator == null) return;
    final key = _messageKey(message);
    if (translatingMessages.contains(key)) return;
    setState(() {
      translatingMessages.add(key);
      translationErrors.remove(key);
      if (retranscribe) translations.remove(key);
    });
    try {
      if (!translator.isInstalled) {
        await translator.install();
        if (!translator.isInstalled) {
          throw StateError(
            translator.errorMessage.isEmpty
                ? 'Gemma 4 installation did not complete'
                : translator.errorMessage,
          );
        }
      }
      final translation = await translate(message, translationLanguage);
      if (!mounted) return;
      setState(() => translations[key] = translation);
      await _speakTranslation(key, translation);
    } catch (error) {
      if (mounted) setState(() => translationErrors[key] = '$error');
    } finally {
      if (mounted) setState(() => translatingMessages.remove(key));
    }
  }

  Future<void> _speakTranslation(
    String key,
    GemmaVoiceTranslation translation,
  ) async {
    final translator = widget.gemmaTranslator;
    if (translator == null) return;
    setState(() => speechErrors.remove(key));
    try {
      await translator.speak(translation);
    } catch (error) {
      if (mounted) setState(() => speechErrors[key] = '$error');
    }
  }

  Future<void> _startVoicePress() async {
    if (voiceStarting || recording) return;
    voicePressed = true;
    voiceStarting = true;
    setState(() => status = 'Requesting microphone');
    final started = await widget.onStartVoiceMessage();
    if (!mounted) return;
    voiceStarting = false;
    if (!voicePressed) {
      if (started) await widget.onStopVoiceMessage(false);
      if (mounted) setState(() => recording = false);
      return;
    }
    setState(() {
      recording = started;
      status = started ? 'Recording' : 'Microphone permission denied';
    });
  }

  Future<void> _finishVoicePress({required bool send}) async {
    voicePressed = false;
    final shouldSend = send && recording;
    if (voiceStarting) {
      setState(() => status = send ? 'Starting voice' : 'Voice cancelled');
      return;
    }
    setState(() {
      recording = false;
      status = shouldSend ? 'Sending voice' : 'Voice cancelled';
    });
    await widget.onStopVoiceMessage(shouldSend);
    if (!mounted) return;
    if (shouldSend) setState(() => status = 'Voice sent');
  }

  Future<void> _startSpeedTest() async {
    if (speedTesting) return;
    setState(() {
      speedTesting = true;
      speedTestSentBytes = 0;
      speedTestTotalBytes = EdgezMeshSdk.speedTestBytes;
      speedTestStartedAtMs = DateTime.now().millisecondsSinceEpoch;
      speedTestSendBitsPerSecond = 0;
      status = 'Speed test started';
    });
    try {
      await widget.onStartSpeedTest(speedTestHop, (sentBytes, totalBytes) {
        if (!mounted) return;
        setState(() {
          speedTestSentBytes = sentBytes;
          speedTestTotalBytes = totalBytes;
          final elapsedMs =
              DateTime.now().millisecondsSinceEpoch - speedTestStartedAtMs;
          if (elapsedMs > 0) {
            speedTestSendBitsPerSecond = sentBytes * 8000 / elapsedMs;
          }
        });
      });
      if (mounted) setState(() => status = 'Speed test sent');
    } catch (error) {
      if (mounted) setState(() => status = 'Speed test failed: $error');
    } finally {
      if (mounted) setState(() => speedTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.activeConnection != EdgezConnectionType.none &&
        widget.user.opensConversation &&
        controller.text.trim().isNotEmpty;
    final canSendVoice = widget.activeConnection != EdgezConnectionType.none;
    final canSendVoiceMessage =
        canSendVoice && widget.user.opensConversation && widget.user.enabled;
    final canSpeedTest = canSendVoice &&
        widget.user.opensConversation &&
        !widget.user.isPublicChannel;
    final speedTestProgress = speedTestTotalBytes <= 0
        ? 0.0
        : (speedTestSentBytes / speedTestTotalBytes).clamp(0.0, 1.0);
    final speedTestPercent = (speedTestProgress * 100).round();
    final speedTestSentKiB = speedTestSentBytes ~/ 1024;
    final speedTestTotalMiB = speedTestTotalBytes / (1024 * 1024);
    final displayName = widget.user.resolvedDisplayName.trim();
    final avatarText = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    EdgezSensorSample? latestLocation;
    for (final sample in widget.sensorSamples) {
      if (sample.data.latitude == null || sample.data.longitude == null) {
        continue;
      }
      if (latestLocation == null ||
          sample.timestampMs > latestLocation.timestampMs) {
        latestLocation = sample;
      }
    }
    final location = latestLocation;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.user.exampleMarker.color,
                  child: Text(
                    avatarText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.user.resolvedDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        widget.user.isPublicChannel
                            ? 'OpenMANET · Port ${widget.user.nodeNum}'
                            : '${widget.user.exampleDeviceType.label} · '
                                '${widget.user.opensConversation ? 'Encrypted' : 'Waiting for key'} · '
                                '${widget.user.nodeId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: widget.user.isPublicChannel
                      ? 'Join OpenMANET talkgroup'
                      : 'Start voice call',
                  onPressed: canSendVoice && widget.callState.isIdle
                      ? () => unawaited(widget.onStartCall())
                      : null,
                  icon: const Icon(Icons.call_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.gemmaTranslator?.isSupported == true) ...<Widget>[
              _GemmaTranslationBar(
                translator: widget.gemmaTranslator!,
                language: translationLanguage,
                languages: supportedVoiceTranslationLanguages,
                onLanguageChanged: (value) {
                  if (value != null) {
                    setState(() => translationLanguage = value);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Icon(
                      location != null ? Icons.gps_fixed : Icons.gps_off,
                      size: 20,
                      color: location != null
                          ? widget.user.exampleMarker.color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        location == null
                            ? 'No sensor GPS'
                            : '${_formatCoordinate(location.data.latitude)}, '
                                '${_formatCoordinate(location.data.longitude)}'
                                '${location.timestampMs > 0 ? ' · ${_formatLocationTime(location.timestampMs)}' : ''}',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.speed,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        speedTesting
                            ? 'Sending: ${_formatBitRate(speedTestSendBitsPerSecond)}'
                                ' · Packet loss: measuring…'
                            : widget.linkStats == null
                                ? 'Speed: — · Packet loss: —'
                                : 'Speed: ${_formatBitRate(widget.linkStats!.bitsPerSecond)}'
                                    ' · Packet loss: '
                                    '${widget.linkStats!.packetLossPercent.toStringAsFixed(2)}%',
                        key: const ValueKey('conversation-link-stats'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: <Widget>[
                  if (widget.messages.isEmpty)
                    const Center(child: Text('No messages yet')),
                  for (final message in widget.messages)
                    ConversationBubble(
                      message: message,
                      onReplayVoiceMessage: widget.onReplayVoiceMessage,
                      translation: translations[_messageKey(message)],
                      translationError: translationErrors[_messageKey(message)],
                      speechError: speechErrors[_messageKey(message)],
                      translating:
                          translatingMessages.contains(_messageKey(message)),
                      canTranslate: widget.gemmaTranslator?.isInstalled == true,
                      onTranslateVoiceMessage:
                          widget.onTranslateVoiceMessage == null
                              ? null
                              : () => _translateVoiceMessage(message),
                      onRetranscribeVoiceMessage: message.transcript.isEmpty ||
                              widget.onRetranscribeVoiceMessage == null
                          ? null
                          : () => _translateVoiceMessage(
                                message,
                                retranscribe: true,
                              ),
                      onSpeakTranslation:
                          translations[_messageKey(message)] == null
                              ? null
                              : () => _speakTranslation(
                                    _messageKey(message),
                                    translations[_messageKey(message)]!,
                                  ),
                    ),
                ],
              ),
            ),
            if (status.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(status,
                      style: Theme.of(context).textTheme.bodySmall)),
            if (recording)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                      child: Text('Recording',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer))),
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Message', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSend
                      ? () async {
                          final text = controller.text.trim();
                          setState(() => status = 'Sending');
                          try {
                            await widget.onSendMessage(text);
                            if (!mounted) return;
                            controller.clear();
                            setState(() => status = 'Sent to device');
                          } catch (error) {
                            if (!mounted) return;
                            setState(() => status = 'Send failed: $error');
                          }
                        }
                      : null,
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 104,
                  child: DropdownButtonFormField<int>(
                    initialValue: speedTestHop,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Hop',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem(
                        value: 0,
                        child:
                            Text('0 (Auto)', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                    ],
                    onChanged: speedTesting
                        ? null
                        : (value) => setState(() => speedTestHop = value ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canSpeedTest && !speedTesting
                        ? () => unawaited(_startSpeedTest())
                        : null,
                    child: Row(
                      children: <Widget>[
                        if (speedTesting)
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              value: speedTestProgress,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(Icons.speed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            speedTesting
                                ? 'Speed test $speedTestPercent% · '
                                    '$speedTestSentKiB KiB / '
                                    '${speedTestTotalMiB.toStringAsFixed(1)} MiB'
                                : 'Speed test (2 MiB)',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: canSendVoiceMessage ? (_) => _startVoicePress() : null,
              onTapUp: canSendVoiceMessage
                  ? (_) => _finishVoicePress(send: true)
                  : null,
              onTapCancel: canSendVoiceMessage
                  ? () => _finishVoicePress(send: false)
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: recording
                      ? Theme.of(context).colorScheme.error
                      : canSendVoiceMessage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recording
                      ? 'Recording'
                      : canSendVoiceMessage
                          ? 'Hold to Talk'
                          : 'Connect to send voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: recording || canSendVoiceMessage
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCoordinate(double? value) =>
    value == null ? '—' : value.toStringAsFixed(6);

String _formatBitRate(double bitsPerSecond) {
  if (bitsPerSecond >= 1000000) {
    return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
  }
  if (bitsPerSecond >= 1000) {
    return '${(bitsPerSecond / 1000).toStringAsFixed(1)} kbps';
  }
  return '${bitsPerSecond.toStringAsFixed(0)} bps';
}

String _formatLocationTime(int timestampMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
}

class _GemmaTranslationBar extends StatelessWidget {
  const _GemmaTranslationBar({
    required this.translator,
    required this.language,
    required this.languages,
    required this.onLanguageChanged,
  });

  final GemmaVoiceTranslator translator;
  final String language;
  final List<String> languages;
  final ValueChanged<String?> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final downloading =
        translator.status == GemmaVoiceTranslatorStatus.downloading;
    final checking = translator.status == GemmaVoiceTranslatorStatus.checking;
    final ready = translator.isInstalled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.translate,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ready
                        ? 'Translate voice'
                        : checking
                            ? 'Checking offline translation…'
                            : downloading
                                ? 'Gemma 4 · ${translator.downloadProgress}%'
                                : 'Offline translation · 2.6 GB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (ready)
                  DropdownButton<String>(
                    value: language,
                    isDense: true,
                    onChanged: onLanguageChanged,
                    items: <DropdownMenuItem<String>>[
                      for (final item in languages)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                  )
                else if (!downloading && !checking)
                  FilledButton.tonal(
                    onPressed: translator.install,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Install'),
                  ),
              ],
            ),
            if (downloading) ...<Widget>[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: translator.downloadProgress / 100,
              ),
            ],
            if (translator.preparingSpeech) ...<Widget>[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: translator.speechDownloadProgress > 0
                    ? translator.speechDownloadProgress / 100
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                translator.speechDownloadProgress < 100
                    ? 'Preparing Moonshine voice · ${translator.speechDownloadProgress}%'
                    : 'Moonshine voice ready',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (translator.errorMessage.isNotEmpty && !downloading)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  translator.errorMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({
    required this.message,
    required this.onReplayVoiceMessage,
    this.translation,
    this.translationError,
    this.speechError,
    this.translating = false,
    this.canTranslate = false,
    this.onTranslateVoiceMessage,
    this.onRetranscribeVoiceMessage,
    this.onSpeakTranslation,
    super.key,
  });

  final EdgezConversationMessage message;
  final ValueChanged<EdgezConversationMessage> onReplayVoiceMessage;
  final GemmaVoiceTranslation? translation;
  final String? translationError;
  final String? speechError;
  final bool translating;
  final bool canTranslate;
  final VoidCallback? onTranslateVoiceMessage;
  final VoidCallback? onRetranscribeVoiceMessage;
  final VoidCallback? onSpeakTranslation;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final isDelivered = message.status == 'Delivered';
    final isVoice = message.isVoice;
    final canReplay = isVoice;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        onTap: canReplay ? () => onReplayVoiceMessage(message) : null,
        borderRadius: BorderRadius.circular(8),
        child: Card(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(isVoice
                          ? 'Voice message ${_formatDuration(message.durationMs)}'
                          : message.text),
                    ),
                    if (isVoice && onTranslateVoiceMessage != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: canTranslate
                            ? 'Translate voice message'
                            : 'Install Gemma 4 to translate',
                        onPressed:
                            !translating ? onTranslateVoiceMessage : null,
                        icon: translating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.translate, size: 20),
                      ),
                    if (isVoice && onRetranscribeVoiceMessage != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Transcribe again using the Settings language',
                        onPressed:
                            !translating ? onRetranscribeVoiceMessage : null,
                        icon: const Icon(Icons.refresh, size: 20),
                      ),
                  ],
                ),
                if (isVoice)
                  Text(
                      message.voiceBytes.isEmpty
                          ? 'No replay data'
                          : 'Tap to replay',
                      style: Theme.of(context).textTheme.labelSmall),
                if (translation != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${translation!.targetLanguage}: ${translation!.translation}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (onSpeakTranslation != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Speak translation',
                          onPressed: onSpeakTranslation,
                          icon: const Icon(Icons.volume_up_outlined, size: 20),
                        ),
                    ],
                  ),
                  if (translation!.transcript.isNotEmpty)
                    Text(
                      'Transcript: ${message.transcript.isNotEmpty ? message.transcript : translation!.transcript}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
                if (translation == null && message.transcript.isNotEmpty)
                  Text(
                    'Transcript${message.transcriptLanguage.isEmpty ? '' : ' (${message.transcriptLanguage})'}: '
                    '${message.transcript}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (translationError?.isNotEmpty == true)
                  Text(
                    'Translation failed: $translationError',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                if (speechError?.isNotEmpty == true)
                  Text(
                    'Speech failed: $speechError',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                if (message.status.isNotEmpty)
                  Text(
                    isDelivered ? 'Delivered' : message.status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDelivered ? const Color(0xFF16803C) : null),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '';
    final seconds = (durationMs / 1000).ceil();
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}
