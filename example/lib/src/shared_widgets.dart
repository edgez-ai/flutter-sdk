import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class HaLowMeshStatusIcon extends StatelessWidget {
  const HaLowMeshStatusIcon({required this.status, super.key});

  final EdgezMeshStatus? status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      null => colorScheme.outline,
      final value when !value.supported => colorScheme.error,
      final value when value.isUsable => colorScheme.primary,
      _ => colorScheme.tertiary,
    };
    return Icon(Icons.hub, color: color);
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

String formatLastSeenAge(int lastSeenMs) {
  if (lastSeenMs <= 0) return 'unknown';
  final elapsed = DateTime.now().millisecondsSinceEpoch - lastSeenMs;
  final seconds = math.max(0, elapsed ~/ 1000);
  if (seconds < 60) return 'just now';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}min';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}hour';
  final days = hours ~/ 24;
  if (days < 7) return '${days}day';
  final weeks = days ~/ 7;
  if (days < 30) return '${weeks}week';
  final months = days ~/ 30;
  if (days < 365) return '${months}month';
  final years = days ~/ 365;
  return '${years}year';
}

String formatCoordinate(double? value) {
  if (value == null) return 'unknown';
  return value.toStringAsFixed(5);
}

String formatSensorValue(double value) {
  return value.abs() >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

extension LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
