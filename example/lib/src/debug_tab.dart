import 'dart:math';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'example_database.dart';
import 'shared_widgets.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({
    required this.activeConnection,
    required this.meshStatus,
    required this.statusLine,
    required this.nodeCount,
    required this.conversationCount,
    required this.shareLocation,
    required this.deviceModeEnabled,
    required this.databaseReady,
    required this.speedMetrics,
    required this.liveSpeedMetric,
    required this.debugLogs,
    required this.onExportLogs,
    required this.onPruneLogs,
    required this.onClose,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? meshStatus;
  final String statusLine;
  final int nodeCount;
  final int conversationCount;
  final bool shareLocation;
  final bool deviceModeEnabled;
  final bool databaseReady;
  final List<ExampleSpeedMetric> speedMetrics;
  final EdgezLinkStats? liveSpeedMetric;
  final List<String> debugLogs;
  final VoidCallback? onExportLogs;
  final VoidCallback? onPruneLogs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final status = meshStatus;
    final live = liveSpeedMetric;
    final displayMetrics = <ExampleSpeedMetric>[
      ...speedMetrics,
      if (live != null &&
          (speedMetrics.isEmpty ||
              live.updatedAtMs > speedMetrics.last.timestampMs))
        ExampleSpeedMetric(
          timestampMs: live.updatedAtMs,
          bitsPerSecond: live.bitsPerSecond,
          packetLossPercent: live.packetLossPercent,
          receivedPackets: live.receivedPackets,
          expectedPackets: live.expectedPackets,
        ),
    ];
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onClose,
                    tooltip: AppLocalizations.of(context).backToSettings,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppLocalizations.of(context).debug,
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  HaLowMeshStatusIcon(status: status),
                ],
              ),
            ),
            TabBar(
              tabs: <Widget>[
                Tab(text: AppLocalizations.of(context).system),
                Tab(text: AppLocalizations.of(context).deviceLogs),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  ListView(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(2400),
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text('System diagnostics',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: AppLocalizations.of(context).speedAndLoss,
                        children: <Widget>[
                          if (displayMetrics.isEmpty)
                            const Text(
                                'No transport traffic in this time window.')
                          else ...<Widget>[
                            DebugValue(
                              label: AppLocalizations.of(context).movingSpeed,
                              value: _formatBitRate(
                                  displayMetrics.last.bitsPerSecond),
                            ),
                            DebugValue(
                              label: AppLocalizations.of(context).movingLoss,
                              value:
                                  '${displayMetrics.last.packetLossPercent.toStringAsFixed(2)}%',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                _ChartLegend(
                                  color: Colors.green.shade600,
                                  label: AppLocalizations.of(context).speed,
                                ),
                                const SizedBox(width: 16),
                                _ChartLegend(
                                  color: Colors.red.shade600,
                                  label: AppLocalizations.of(context).loss,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _SpeedHistoryPainter(
                                  metrics: displayMetrics,
                                  speedColor: Colors.green.shade600,
                                  lossColor: Colors.red.shade600,
                                  gridColor: Theme.of(context).dividerColor,
                                  labelColor: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '${displayMetrics.length} sample${displayMetrics.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: AppLocalizations.of(context).transport,
                        children: <Widget>[
                          DebugValue(
                              label:
                                  AppLocalizations.of(context).activeConnection,
                              value: activeConnection.name.toUpperCase()),
                          DebugValue(
                              label: AppLocalizations.of(context).status,
                              value: statusLine.isEmpty
                                  ? 'No status'
                                  : statusLine),
                          DebugValue(
                              label: AppLocalizations.of(context).knownNodes,
                              value: nodeCount.toString()),
                          DebugValue(
                              label: AppLocalizations.of(context).conversations,
                              value: conversationCount.toString()),
                          DebugValue(
                              label: AppLocalizations.of(context).shareLocation,
                              value: shareLocation ? 'Enabled' : 'Disabled'),
                          DebugValue(
                              label: AppLocalizations.of(context).deviceMode,
                              value:
                                  deviceModeEnabled ? 'Enabled' : 'Disabled'),
                          DebugValue(
                              label: AppLocalizations.of(context).database,
                              value: databaseReady ? 'Enabled' : 'Memory only'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: AppLocalizations.of(context).halowMesh,
                        children: status == null
                            ? const <Widget>[
                                Text('No HaLow status received yet')
                              ]
                            : <Widget>[
                                DebugValue(
                                    label:
                                        AppLocalizations.of(context).supported,
                                    value: status.supported.toString()),
                                DebugValue(
                                    label: AppLocalizations.of(context)
                                        .initialized,
                                    value: status.stackInitialized.toString()),
                                DebugValue(
                                    label:
                                        AppLocalizations.of(context).meshMode,
                                    value: status.meshMode.toString()),
                                DebugValue(
                                    label: AppLocalizations.of(context).linkUp,
                                    value: status.linkUp.toString()),
                                DebugValue(
                                    label:
                                        AppLocalizations.of(context).routeReady,
                                    value: status.routeReady.toString()),
                                DebugValue(
                                    label: AppLocalizations.of(context)
                                        .readyForReport,
                                    value: status.readyForReport.toString()),
                                DebugValue(
                                    label: AppLocalizations.of(context).license,
                                    value: status.licenseStatus.label),
                                DebugValue(
                                    label: 'Mesh ID',
                                    value: status.meshId.isEmpty
                                        ? 'none'
                                        : status.meshId),
                                DebugValue(
                                    label: 'IP',
                                    value: status.ipAddress.isEmpty
                                        ? 'none'
                                        : status.ipAddress),
                                DebugValue(
                                    label: AppLocalizations.of(context).gateway,
                                    value: status.gateway.isEmpty
                                        ? 'none'
                                        : status.gateway),
                                DebugValue(
                                    label: 'MAC',
                                    value: status.macAddress == 0
                                        ? 'none'
                                        : status.macAddress.toRadixString(16)),
                              ],
                      ),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: AppLocalizations.of(context).sdkEvents,
                        children: <Widget>[
                          Text(
                            statusLine.isEmpty
                                ? 'Events from the BLE SDK will appear here as status text.'
                                : statusLine,
                          ),
                        ],
                      ),
                    ],
                  ),
                  ListView(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(2400),
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Text(AppLocalizations.of(context).deviceLogs,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      InfoCard(
                        title: AppLocalizations.of(context).logStream,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: onExportLogs,
                                icon: const Icon(Icons.file_download_outlined),
                                label:
                                    Text(AppLocalizations.of(context).download),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: onPruneLogs == null
                                    ? null
                                    : () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Prune logs?'),
                                            content: const Text(
                                              'This permanently clears the log files and the current log view.',
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(
                                                    AppLocalizations.of(context)
                                                        .cancel),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(
                                                    AppLocalizations.of(context)
                                                        .prune),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          onPruneLogs?.call();
                                        }
                                      },
                                icon: const Icon(Icons.delete_sweep_outlined),
                                label: Text(AppLocalizations.of(context).prune),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (debugLogs.isEmpty)
                            const Text(
                                'No device logs received on this connection yet.')
                          else
                            SizedBox(
                              height: 520,
                              child: _DeviceLogList(lines: debugLogs),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceLogList extends StatefulWidget {
  const _DeviceLogList({required this.lines});

  final List<String> lines;

  @override
  State<_DeviceLogList> createState() => _DeviceLogListState();
}

class _DeviceLogListState extends State<_DeviceLogList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottomAfterLayout();
  }

  @override
  void didUpdateWidget(covariant _DeviceLogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.isEmpty && widget.lines.isNotEmpty) {
      _scrollToBottomAfterLayout();
    }
  }

  void _scrollToBottomAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.lines.length,
      itemBuilder: (context, index) => SelectableText(
        widget.lines[index],
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

String _formatBitRate(double bitsPerSecond) {
  if (bitsPerSecond >= 1000000) {
    return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
  }
  return '${(bitsPerSecond / 1000).toStringAsFixed(1)} kbps';
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SpeedHistoryPainter extends CustomPainter {
  const _SpeedHistoryPainter({
    required this.metrics,
    required this.speedColor,
    required this.lossColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<ExampleSpeedMetric> metrics;
  final Color speedColor;
  final Color lossColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTRB(54, 8, size.width - 42, size.height - 22);
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var line = 0; line <= 4; line++) {
      final y = bounds.top + bounds.height * line / 4;
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), grid);
    }
    if (metrics.isEmpty) return;
    final maxSpeed = metrics.fold<double>(
      1,
      (maximum, item) => max(maximum, item.bitsPerSecond),
    );
    final endMs = DateTime.now().millisecondsSinceEpoch;
    final startMs = endMs - const Duration(minutes: 30).inMilliseconds;

    void drawLabel(String text, Offset offset, {required bool alignRight}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(alignRight ? offset.dx - painter.width : offset.dx, offset.dy),
      );
    }

    for (var line = 0; line <= 4; line++) {
      final fraction = 1 - line / 4;
      final y = bounds.top + bounds.height * line / 4 - 6;
      drawLabel(
        _formatAxisBitRate(maxSpeed * fraction),
        Offset(bounds.left - 6, y),
        alignRight: true,
      );
      drawLabel(
        '${(100 * fraction).round()}%',
        Offset(bounds.right + 6, y),
        alignRight: false,
      );
    }
    drawLabel('-30m', Offset(bounds.left, bounds.bottom + 5),
        alignRight: false);
    drawLabel('now', Offset(bounds.right, bounds.bottom + 5), alignRight: true);

    Path pathFor(double Function(ExampleSpeedMetric metric) normalizedValue) {
      final path = Path();
      for (var index = 0; index < metrics.length; index++) {
        final metric = metrics[index];
        final xFraction = ((metric.timestampMs - startMs) / (endMs - startMs))
            .clamp(0.0, 1.0);
        final yFraction = normalizedValue(metric).clamp(0.0, 1.0);
        final point = Offset(
          bounds.left + bounds.width * xFraction,
          bounds.bottom - bounds.height * yFraction,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    final speedPaint = Paint()
      ..color = speedColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final lossPaint = Paint()
      ..color = lossColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        pathFor((item) => item.bitsPerSecond / maxSpeed), speedPaint);
    canvas.drawPath(
      pathFor((item) => item.packetLossPercent / 100),
      lossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedHistoryPainter oldDelegate) =>
      oldDelegate.metrics != metrics ||
      oldDelegate.speedColor != speedColor ||
      oldDelegate.lossColor != lossColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}

String _formatAxisBitRate(double bitsPerSecond) {
  if (bitsPerSecond >= 1000000) {
    return '${(bitsPerSecond / 1000000).toStringAsFixed(1)}M';
  }
  if (bitsPerSecond >= 1000) {
    return '${(bitsPerSecond / 1000).toStringAsFixed(0)}k';
  }
  return bitsPerSecond.toStringAsFixed(0);
}

class DebugValue extends StatelessWidget {
  const DebugValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
