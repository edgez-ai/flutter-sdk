import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'driver_catalog.dart';

const _edgezMarketplaceUrl = 'https://www.edgez.ai/mobile/marketplace';

class DriversScreen extends StatelessWidget {
  const DriversScreen({required this.drivers, super.key});

  final List<ExampleDriver> drivers;

  @override
  Widget build(BuildContext context) {
    final uartI2c = drivers
        .where((driver) => driver.connector.name == 'uartI2c')
        .toList(growable: false);
    final rs485 = drivers
        .where((driver) => driver.connector.name == 'rs485')
        .toList(growable: false);
    return SafeArea(
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
          Text('UART / I2C', style: Theme.of(context).textTheme.titleMedium),
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
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final ExampleDriver driver;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
