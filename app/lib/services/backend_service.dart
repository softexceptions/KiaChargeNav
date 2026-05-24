import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class BackendException implements Exception {
  final int statusCode;
  final String message;
  const BackendException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class BackendService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  BackendService({
    required this._baseUrl,
    required this._apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Api-Key': _apiKey,
      };

  Future<Station> findStation({
    required double lat,
    required double lon,
    required double heading,
    required String network,
    double radiusKm = 15.0,
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$_baseUrl/find'),
          headers: _headers,
          body: jsonEncode({
            'lat': lat,
            'lon': lon,
            'heading': heading,
            'network': network,
            'radius_km': radiusKm,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 200) {
      return Station.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    }
    if (resp.statusCode == 404) {
      final detail = (jsonDecode(resp.body) as Map)['detail'] ?? 'Keine Station gefunden';
      throw BackendException(404, detail as String);
    }
    throw BackendException(resp.statusCode, 'Backend-Fehler ${resp.statusCode}');
  }

  Future<void> sendToKia(Station station) async {
    final resp = await _client
        .post(
          Uri.parse('$_baseUrl/send'),
          headers: _headers,
          body: jsonEncode({
            'name': station.name,
            'address': station.address,
            'lat': station.lat,
            'lon': station.lon,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      final detail = (jsonDecode(resp.body) as Map?)?.containsKey('detail') == true
          ? (jsonDecode(resp.body) as Map)['detail']
          : 'Fahrzeug nicht erreichbar';
      throw BackendException(resp.statusCode, detail as String);
    }
  }
}
