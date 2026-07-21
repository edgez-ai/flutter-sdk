import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.activeConnection,
    required this.user,
    required this.messages,
    required this.sensorSamples,
    required this.onBack,
    required this.onSendMessage,
    required this.onStartVoiceMessage,
    required this.onStopVoiceMessage,
    required this.onReplayVoiceMessage,
    required this.callState,
    required this.onStartCall,
    required this.onAcceptCall,
    required this.onEndCall,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshNode user;
  final List<EdgezConversationMessage> messages;
  final List<EdgezSensorSample> sensorSamples;
  final VoidCallback onBack;
  final ValueChanged<String> onSendMessage;
  final Future<bool> Function() onStartVoiceMessage;
  final Future<void> Function(bool send) onStopVoiceMessage;
  final ValueChanged<EdgezConversationMessage> onReplayVoiceMessage;
  final EdgezVoiceCallState callState;
  final Future<void> Function() onStartCall;
  final Future<void> Function() onAcceptCall;
  final Future<void> Function() onEndCall;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController controller = TextEditingController();
  String status = '';
  bool recording = false;
  bool voicePressed = false;
  bool voiceStarting = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final canSend = widget.activeConnection != EdgezConnectionType.none &&
        widget.user.opensConversation &&
        controller.text.trim().isNotEmpty;
    final canSendVoice = widget.activeConnection != EdgezConnectionType.none;
    final callForThisUser = widget.callState.peerNodeNum == widget.user.nodeNum;
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
                  tooltip: widget.callState.isIdle
                      ? 'Start voice call'
                      : callForThisUser
                          ? 'End voice call'
                          : 'Another call is active',
                  onPressed: !canSendVoice
                      ? null
                      : widget.callState.isIdle
                          ? () => unawaited(widget.onStartCall())
                          : callForThisUser
                              ? () => unawaited(widget.onEndCall())
                              : null,
                  icon: Icon(
                    widget.callState.isIdle
                        ? Icons.call_outlined
                        : Icons.call_end,
                  ),
                ),
              ],
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
            if (callForThisUser && !widget.callState.isIdle) ...<Widget>[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          switch (widget.callState.phase) {
                            EdgezVoiceCallPhase.outgoing => 'Calling...',
                            EdgezVoiceCallPhase.incoming =>
                              'Incoming voice call',
                            EdgezVoiceCallPhase.active => 'Voice call active',
                            EdgezVoiceCallPhase.idle => '',
                          },
                        ),
                      ),
                      if (widget.callState.phase ==
                          EdgezVoiceCallPhase.incoming)
                        FilledButton(
                          onPressed: () => unawaited(widget.onAcceptCall()),
                          child: const Text('Accept'),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => unawaited(widget.onEndCall()),
                        child: const Text('End'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                      ? () {
                          final text = controller.text.trim();
                          widget.onSendMessage(text);
                          controller.clear();
                          setState(() => status = 'Sent');
                        }
                      : null,
                  child: const Text('Send'),
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

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({
    required this.message,
    required this.onReplayVoiceMessage,
    super.key,
  });

  final EdgezConversationMessage message;
  final ValueChanged<EdgezConversationMessage> onReplayVoiceMessage;

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
                Text(isVoice
                    ? 'Voice message ${_formatDuration(message.durationMs)}'
                    : message.text),
                if (isVoice)
                  Text(
                      message.voiceBytes.isEmpty
                          ? 'No replay data'
                          : 'Tap to replay',
                      style: Theme.of(context).textTheme.labelSmall),
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
