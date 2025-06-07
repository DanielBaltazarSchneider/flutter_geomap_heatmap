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

  static List<List<GeoSampling>> agruparPorIntervalos({
    required List<GeoSampling> amostras,
    int partes = 10,
    double? min,
    double? max,
  }) {
    // Filtra valores válidos
    final validas = amostras.where((a) => a.value.isFinite).toList();
    if (validas.isEmpty || partes <= 0) return [];

    // Calcula min e max se não informados
    final valorMin = min ?? validas.map((a) => a.value).reduce((a, b) => a < b ? a : b);
    final valorMax = max ?? validas.map((a) => a.value).reduce((a, b) => a > b ? a : b);

    if (valorMax == valorMin) {
      // Evita divisão por zero
      return [validas];
    }

    final intervalo = (valorMax - valorMin) / partes;
    List<List<GeoSampling>> grupos = List.generate(partes, (_) => []);

    for (var amostra in validas) {
      int indice = ((amostra.value - valorMin) / intervalo).floor();
      if (indice < 0) indice = 0;
      if (indice >= partes) indice = partes - 1;
      grupos[indice].add(amostra);
    }

    return grupos;
  }
}
