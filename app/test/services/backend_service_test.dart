import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:kia_charge_nav/services/backend_service.dart';
import 'package:kia_charge_nav/models/station.dart';

class _MockClient extends Mock implements http.Client {}

const _stationJson = {
  'name': 'Shell Recharge A1',
  'address': 'Autobahn A1, Hamburg',
  'lat': 53.55,
  'lon': 9.99,
  'distance_km': 4.2,
  'heading_diff_deg': 12.0,
  'operator': 'Shell Recharge',
};

void main() {
  late _MockClient mockClient;
  late BackendService sut;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockClient = _MockClient();
    sut = BackendService(
      baseUrl: 'http://localhost:8000',
      apiKey: 'test-key',
      client: mockClient,
    );
  });

  group('findStation', () {
    test('gibt Station zurück bei 200', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(_stationJson), 200));

      final station = await sut.findStation(lat: 53.5, lon: 9.9, heading: 90, network: 'shell');

      expect(station.name, 'Shell Recharge A1');
      expect(station.distanceKm, 4.2);
    });

    test('wirft BackendException bei 404', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'detail': 'Keine Shell-Station gefunden'}),
                404,
              ));

      expect(
        () => sut.findStation(lat: 53.5, lon: 9.9, heading: 90, network: 'shell'),
        throwsA(isA<BackendException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('wirft BackendException bei 5xx', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 502));

      expect(
        () => sut.findStation(lat: 53.5, lon: 9.9, heading: 90, network: 'shell'),
        throwsA(isA<BackendException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
    });
  });

  group('sendToKia', () {
    const station = Station(
      name: 'Shell A1',
      address: 'A1, HH',
      lat: 53.55,
      lon: 9.99,
      distanceKm: 4.2,
      headingDiffDeg: 12.0,
      operator: 'Shell Recharge',
    );

    test('erfolgreich bei 200', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({'status': 'sent'}), 200));

      await expectLater(sut.sendToKia(station), completes);
    });

    test('wirft BackendException bei Fehler', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'detail': 'Fahrzeug nicht erreichbar'}),
                502,
              ));

      expect(
        () => sut.sendToKia(station),
        throwsA(isA<BackendException>()),
      );
    });
  });
}
