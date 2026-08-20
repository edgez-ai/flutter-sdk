import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.call,
    required this.peer,
    required this.onAnswer,
    required this.onEnd,
    this.onTalkStart,
    this.onTalkEnd,
  });

  final EdgezVoiceCallState call;
  final EdgezMeshNode? peer;
  final Future<void> Function() onAnswer;
  final Future<void> Function() onEnd;
  final Future<void> Function()? onTalkStart;
  final Future<void> Function()? onTalkEnd;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  Timer? timer;
  DateTime? connectedAt;
  bool actionInProgress = false;
  bool transmitting = false;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(VoiceCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.phase != widget.call.phase) _updateTimer();
  }

  void _updateTimer() {
    timer?.cancel();
    if (widget.call.phase != EdgezVoiceCallPhase.active) {
      connectedAt = null;
      return;
    }
    connectedAt ??= DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (actionInProgress) return;
    setState(() => actionInProgress = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call action failed: $error')),
      );
    } finally {
      if (mounted) setState(() => actionInProgress = false);
    }
  }

  Future<void> _setTalking(bool enabled) async {
    if (transmitting == enabled) return;
    setState(() => transmitting = enabled);
    try {
      if (enabled) {
        await widget.onTalkStart?.call();
      } else {
        await widget.onTalkEnd?.call();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => transmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice transmission failed: $error')),
      );
    }
  }

  String get _status {
    switch (widget.call.phase) {
      case EdgezVoiceCallPhase.incoming:
        return 'Incoming voice call';
      case EdgezVoiceCallPhase.outgoing:
        return 'Calling…';
      case EdgezVoiceCallPhase.active:
        final start = connectedAt;
        if (start == null) return 'Connected';
        final elapsed = DateTime.now().difference(start);
        final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      case EdgezVoiceCallPhase.idle:
        return 'Call ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final peerName = widget.peer?.resolvedDisplayName ?? 'Mesh user';
    final isOpenManet = widget.peer?.isPublicChannel == true;
    final isIncoming = widget.call.phase == EdgezVoiceCallPhase.incoming;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xff102a2a),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
            child: Column(
              children: <Widget>[
                Text(
                  isOpenManet ? 'OpenMANET Comms' : 'EdgeZ Voice',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.shade600,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    isOpenManet ? Icons.campaign : Icons.person,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  peerName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                if (widget.call.phase ==
                    EdgezVoiceCallPhase.active) ...<Widget>[
                  const SizedBox(height: 28),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => unawaited(_setTalking(true)),
                    onTapUp: (_) => unawaited(_setTalking(false)),
                    onTapCancel: () => unawaited(_setTalking(false)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: transmitting
                            ? Colors.orange.shade700
                            : Colors.teal.shade500,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        transmitting ? 'Transmitting…' : 'Hold to Talk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                if (actionInProgress)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                Row(
                  mainAxisAlignment: isIncoming
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: <Widget>[
                    _CallAction(
                      label: isIncoming ? 'Decline' : 'End',
                      icon: Icons.call_end,
                      color: Colors.red.shade600,
                      enabled: !actionInProgress,
                      onPressed: () => _run(widget.onEnd),
                    ),
                    if (isIncoming)
                      _CallAction(
                        label: 'Answer',
                        icon: Icons.call,
                        color: Colors.green.shade600,
                        enabled: !actionInProgress,
                        onPressed: () => _run(widget.onAnswer),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton.filled(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          iconSize: 34,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withValues(alpha: 0.45),
            minimumSize: const Size.square(72),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
