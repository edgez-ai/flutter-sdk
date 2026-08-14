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
    this.gemmaTranslator,
    this.onTranslateVoiceMessage,
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
  final GemmaVoiceTranslator? gemmaTranslator;
  final Future<GemmaVoiceTranslation> Function(
    EdgezConversationMessage message,
    String targetLanguage,
  )? onTranslateVoiceMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const _translationLanguages = <String>[
    'Arabic',
    'Chinese',
    'English',
    'Japanese',
    'Korean',
    'Spanish',
  ];
  final TextEditingController controller = TextEditingController();
  String status = '';
  bool recording = false;
  bool voicePressed = false;
  bool voiceStarting = false;
  bool speedTesting = false;
  int speedTestSentBytes = 0;
  int speedTestTotalBytes = EdgezMeshSdk.speedTestBytes;
  int speedTestHop = 0;
  String translationLanguage = 'English';
  final Map<String, GemmaVoiceTranslation> translations =
      <String, GemmaVoiceTranslation>{};
  final Map<String, String> translationErrors = <String, String>{};
  final Map<String, String> speechErrors = <String, String>{};
  final Set<String> translatingMessages = <String>{};

  @override
  void initState() {
    super.initState();
    widget.gemmaTranslator?.addListener(_gemmaChanged);
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gemmaTranslator != widget.gemmaTranslator) {
      oldWidget.gemmaTranslator?.removeListener(_gemmaChanged);
      widget.gemmaTranslator?.addListener(_gemmaChanged);
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

  Future<void> _translateVoiceMessage(
    EdgezConversationMessage message,
  ) async {
    final translate = widget.onTranslateVoiceMessage;
    final translator = widget.gemmaTranslator;
    if (translate == null || translator == null) return;
    final key = _messageKey(message);
    if (translatingMessages.contains(key)) return;
    setState(() {
      translatingMessages.add(key);
      translationErrors.remove(key);
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
      status = 'Speed test started';
    });
    try {
      await widget.onStartSpeedTest(speedTestHop, (sentBytes, totalBytes) {
        if (!mounted) return;
        setState(() {
          speedTestSentBytes = sentBytes;
          speedTestTotalBytes = totalBytes;
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
    final canSpeedTest = canSendVoice && widget.user.opensConversation;
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
                    children: <Widget>[
                      Text(
                        widget.user.resolvedDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${widget.user.exampleDeviceType.label} · '
                        '${widget.user.opensConversation ? 'Encrypted' : 'Waiting for key'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        widget.user.nodeId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Start voice call',
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
                languages: _translationLanguages,
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.speed,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.linkStats == null
                            ? 'Speed: — · Packet loss: —'
                            : 'Speed: ${_formatBitRate(widget.linkStats!.bitsPerSecond)} · '
                                'Packet loss: ${widget.linkStats!.packetLossPercent.toStringAsFixed(2)}%',
                        key: const ValueKey<String>('conversation-link-stats'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      location != null ? Icons.gps_fixed : Icons.gps_off,
                      color: location != null
                          ? widget.user.exampleMarker.color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Latest sensor location',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (location != null) ...<Widget>[
                            SelectableText(
                              '${_formatCoordinate(location.data.latitude)}, '
                              '${_formatCoordinate(location.data.longitude)}',
                            ),
                            if (location.timestampMs > 0)
                              Text(
                                'Updated ${_formatLocationTime(location.timestampMs)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ] else
                            Text(
                              'No GPS location received in sensor data',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.user.opensConversation
                    ? 'Encrypted with ECDH + AES-GCM'
                    : "Waiting for this user's public key",
                style: TextStyle(
                    color: widget.user.opensConversation
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error),
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
              onTapDown: canSendVoice ? (_) => _startVoicePress() : null,
              onTapUp:
                  canSendVoice ? (_) => _finishVoicePress(send: true) : null,
              onTapCancel:
                  canSendVoice ? () => _finishVoicePress(send: false) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: recording
                      ? Theme.of(context).colorScheme.error
                      : canSendVoice
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recording
                      ? 'Recording'
                      : canSendVoice
                          ? 'Hold to Talk'
                          : 'Connect to send voice',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: recording || canSendVoice
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

String _formatLocationTime(int timestampMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
}

String _formatBitRate(double bitsPerSecond) {
  if (bitsPerSecond >= 1000000) {
    return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
  }
  if (bitsPerSecond >= 1000) {
    return '${(bitsPerSecond / 1000).toStringAsFixed(1)} kbps';
  }
  return '${bitsPerSecond.toStringAsFixed(0)} bps';
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
    final ready = translator.isInstalled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.translate,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ready
                        ? 'Gemma 4 offline voice translation'
                        : downloading
                            ? 'Downloading Gemma 4 · ${translator.downloadProgress}%'
                            : 'Offline voice translation · 2.6 GB download',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (ready)
                  DropdownButton<String>(
                    value: language,
                    onChanged: onLanguageChanged,
                    items: <DropdownMenuItem<String>>[
                      for (final item in languages)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                  )
                else if (!downloading)
                  FilledButton.tonal(
                    onPressed: translator.install,
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
                      'Transcript: ${translation!.transcript}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
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
