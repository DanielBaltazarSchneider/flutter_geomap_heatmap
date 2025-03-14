import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/src/coordinate.dart';

class GeoSampling {
  GeoSampling({required this.polygon, required this.value, this.color = Colors.transparent});

  List<Coordinate> polygon;
  double value;
  Color color;

  factory GeoSampling.fromMap(Map<String, dynamic> map) {
    return GeoSampling(
      polygon: List<Coordinate>.from(
        (map['polygon'] as List).map(
          (e) => Coordinate(lat: e['lat'], lng: e['lng']),
        ),
      ),
      value: map['value'],
      color: Color(map['color']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'polygon': polygon.map((e) => {'lat': e.lat, 'lng': e.lng}).toList(),
      'value': value,
      'color': color.toARGB32(),
    };
  }
}
