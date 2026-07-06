import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.activeConnection,
    required this.user,
    required this.messages,
    required this.onBack,
    required this.onSendMessage,
    required this.onSendVoiceMessage,
    required this.onReplayVoiceMessage,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshNode user;
  final List<EdgezConversationMessage> messages;
  final VoidCallback onBack;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onSendVoiceMessage;
  final ValueChanged<EdgezConversationMessage> onReplayVoiceMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController controller = TextEditingController();
  String status = '';
  bool recording = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.activeConnection != EdgezConnectionType.none &&
        widget.user.opensConversation &&
        controller.text.trim().isNotEmpty;
    final canSendVoice = widget.activeConnection != EdgezConnectionType.none;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextButton(onPressed: widget.onBack, child: const Text('Back')),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (widget.user.hasLocation)
                      Icon(Icons.location_on,
                          color: widget.user.exampleMarker.color),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(widget.user.resolvedDisplayName,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Node ${widget.user.nodeId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('User ${widget.user.exampleUserId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Marker ${widget.user.exampleMarker.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Type ${widget.user.exampleDeviceType.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (widget.user.exampleGeoFenceName.isNotEmpty)
                          Text('Geofence ${widget.user.exampleGeoFenceName}',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (widget.user.sleeping)
                          Text('Sleeping',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ],
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
              onLongPressStart:
                  canSendVoice ? (_) => setState(() => recording = true) : null,
              onLongPressEnd: canSendVoice
                  ? (_) {
                      setState(() {
                        recording = false;
                        status = 'Voice sent';
                      });
                      widget.onSendVoiceMessage();
                    }
                  : null,
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
