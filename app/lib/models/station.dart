class Station {
  final String name;
  final String address;
  final double lat;
  final double lon;
  final double distanceKm;
  final double headingDiffDeg;
  final String operator;

  const Station({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    required this.headingDiffDeg,
    required this.operator,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        name: json['name'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        distanceKm: (json['distance_km'] as num).toDouble(),
        headingDiffDeg: (json['heading_diff_deg'] as num).toDouble(),
        operator: json['operator'] as String,
      );
}
