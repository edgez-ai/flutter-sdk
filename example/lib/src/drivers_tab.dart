import 'dart:async';
import 'dart:io';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'driver_catalog.dart';
import 'marketplace_driver_install.dart';

const _edgezMarketplaceUrl = 'https://www.edgez.ai/mobile/marketplace';

class DriversScreen extends StatefulWidget {
  const DriversScreen({
    required this.drivers,
    required this.driverStore,
    required this.onInstalled,
    this.installRequest,
    this.onInstallHandled,
    this.marketplaceClient,
    super.key,
  });

  final List<ExampleDriver> drivers;
  final EdgezDriverStore driverStore;
  final MarketplaceDriverInstallRequest? installRequest;
  final VoidCallback? onInstallHandled;
  final FutureOr<void> Function() onInstalled;
  final MarketplaceDriverClient? marketplaceClient;

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  late final MarketplaceDriverClient client;
  late final bool ownsClient;
  MarketplaceDriverDownload? pendingInstall;
  bool loadingInstall = false;
  String? installError;

  @override
  void initState() {
    super.initState();
    ownsClient = widget.marketplaceClient == null;
    client = widget.marketplaceClient ?? MarketplaceDriverClient();
    if (widget.installRequest != null) {
      unawaited(_prepareInstall(widget.installRequest!));
    }
  }

  @override
  void didUpdateWidget(covariant DriversScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.installRequest;
    if (request != null &&
        (request.itemId != oldWidget.installRequest?.itemId ||
            request.slug != oldWidget.installRequest?.slug)) {
      unawaited(_prepareInstall(request));
    }
  }

  @override
  void dispose() {
    if (ownsClient) client.close();
    super.dispose();
  }

  Future<void> _prepareInstall(MarketplaceDriverInstallRequest request) async {
    setState(() {
      loadingInstall = true;
      pendingInstall = null;
      installError = null;
    });
    try {
      final downloaded = await client.fetch(request);
      if (mounted) setState(() => pendingInstall = downloaded);
    } catch (error) {
      if (mounted) {
        setState(() => installError =
            error is FormatException ? error.message : error.toString());
      }
    } finally {
      if (mounted) setState(() => loadingInstall = false);
    }
  }

  Future<void> _install() async {
    final download = pendingInstall;
    if (download == null) return;
    setState(() {
      pendingInstall = null;
      loadingInstall = true;
      installError = null;
    });
    try {
      final image = await client.downloadImage(download.imageUrl);
      await widget.driverStore.save(download.bundle, imageBytes: image);
      await Future<void>.value(widget.onInstalled());
      _finishInstall();
    } catch (error) {
      if (mounted) {
        setState(() => installError =
            error is FormatException ? error.message : error.toString());
      }
    } finally {
      if (mounted) setState(() => loadingInstall = false);
    }
  }

  void _finishInstall() {
    if (!mounted) return;
    setState(() {
      pendingInstall = null;
      installError = null;
    });
    widget.onInstallHandled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final uartI2c = widget.drivers
        .where((driver) => driver.connector == EdgezSensorConnector.uartI2c)
        .toList(growable: false);
    final rs485 = widget.drivers
        .where((driver) => driver.connector == EdgezSensorConnector.rs485)
        .toList(growable: false);
    return Stack(
      children: <Widget>[
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Drivers',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  FilledButton(
                    onPressed: () => launchUrl(
                      Uri.parse(_edgezMarketplaceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Marketplace'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('UART / I2C',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final driver in uartI2c) ...<Widget>[
                _DriverCard(driver: driver),
                const SizedBox(height: 12),
              ],
              Text('RS485', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final driver in rs485) ...<Widget>[
                _DriverCard(driver: driver),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (loadingInstall) ...const <Widget>[
          Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Color(0x55000000)),
          ),
          Center(child: CircularProgressIndicator()),
        ],
        if (pendingInstall case final download?) ...<Widget>[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Color(0x55000000)),
          ),
          Center(
            child: AlertDialog(
              title: Text('Install ${download.bundle.name}?'),
              content: Text(
                'This adds the ${download.bundle.connector == EdgezSensorConnector.rs485 ? 'RS485' : 'UART / I2C'} driver to this app. You can then select it when provisioning a connected device.',
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: _finishInstall, child: const Text('Cancel')),
                FilledButton(onPressed: _install, child: const Text('Install')),
              ],
            ),
          ),
        ],
        if (installError case final message?) ...<Widget>[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Color(0x55000000)),
          ),
          Center(
            child: AlertDialog(
              title: const Text('Driver install failed'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                    onPressed: _finishInstall, child: const Text('Close')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final ExampleDriver driver;

  @override
  Widget build(BuildContext context) {
    final installedImage =
        driver.imagePath.isEmpty ? null : FileImage(File(driver.imagePath));
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (installedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: installedImage,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 104,
                    height: 104,
                    child: Icon(Icons.usb),
                  ),
                ),
              )
            else
              Icon(Icons.usb, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(driver.name,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      if (driver.isBundled)
                        const Tooltip(
                          message: 'Built-in driver',
                          child: Icon(Icons.verified, size: 16),
                        ),
                    ],
                  ),
                  if (driver.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(driver.description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
