import 'dart:convert';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:edgez_flutter_sdk_example/src/marketplace_driver_install.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const itemId = '12345678-1234-1234-1234-123456789abc';

  test('accepts only the Android-compatible driver install URI', () {
    final request = MarketplaceDriverInstallRequest.fromUri(
      Uri.parse('edgez://drivers/install?id=$itemId&slug=sht3x-driver'),
    );

    expect(request?.itemId, itemId);
    expect(request?.slug, 'sht3x-driver');
    expect(
      MarketplaceDriverInstallRequest.fromUri(
        Uri.parse('https://drivers/install?id=$itemId&slug=sht3x-driver'),
      ),
      isNull,
    );
    expect(
      MarketplaceDriverInstallRequest.fromUri(
        Uri.parse('edgez://drivers/install?id=bad&slug=Bad Slug'),
      ),
      isNull,
    );
  });

  test('validates and maps a marketplace driver response', () async {
    final httpClient = MockClient((request) async {
      expect(request.url.path, '/api/marketplace/items/sht3x-driver');
      return http.Response.bytes(
        utf8.encode(jsonEncode(<String, Object?>{
          'id': itemId,
          'slug': 'sht3x-driver',
          'type': 'driver',
          'title': 'SHT3x',
          'snapshotImageUrl': 'https://www.edgez.ai/sht3x.png',
          'driverBundle': <String, Object?>{
            'format': 'edgez-driver/v1',
            'driverId': 'ai.edgez.sht3x-marketplace',
            'key': '3002-1',
            'scriptId': 3002,
            'version': 1,
            'name': 'Marketplace SHT3x',
            'interface': 'uart_i2c',
            'script': 'return { temperature = 21 }',
            'description': 'A downloaded driver',
            'globalBufferSize': 8192,
          },
        })),
        200,
        headers: const <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final client = MarketplaceDriverClient(client: httpClient);
    addTearDown(client.close);
    const request = MarketplaceDriverInstallRequest(
      itemId: itemId,
      slug: 'sht3x-driver',
    );

    final download = await client.fetch(request);

    expect(download.bundle.driverId, 'ai.edgez.sht3x-marketplace');
    expect(download.bundle.connector, EdgezSensorConnector.uartI2c);
    expect(download.bundle.globalBufferSize, 8192);
    expect(download.bundle.marketplaceItemId, itemId);
    expect(download.imageUrl, Uri.parse('https://www.edgez.ai/sht3x.png'));
  });

  test('rejects a response that does not match the deep link', () async {
    final client = MarketplaceDriverClient(
      client: MockClient((_) async => http.Response(
            jsonEncode(<String, Object?>{
              'id': 'ffffffff-ffff-ffff-ffff-ffffffffffff',
              'slug': 'sht3x-driver',
              'type': 'driver',
            }),
            200,
          )),
    );
    addTearDown(client.close);

    expect(
      () => client.fetch(const MarketplaceDriverInstallRequest(
        itemId: itemId,
        slug: 'sht3x-driver',
      )),
      throwsFormatException,
    );
  });

  test('downloads and validates an HTTPS driver image', () async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final client = MarketplaceDriverClient(
      client: MockClient((_) async => http.Response.bytes(
            png,
            200,
            headers: const <String, String>{'content-type': 'image/png'},
          )),
    );
    addTearDown(client.close);

    final downloaded = await client.downloadImage(
      Uri.parse('https://www.edgez.ai/driver.png'),
    );

    expect(downloaded, png);
    expect(
      () => client.downloadImage(Uri.parse('http://www.edgez.ai/driver.png')),
      throwsFormatException,
    );
  });
}
