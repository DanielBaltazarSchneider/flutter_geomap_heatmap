import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/src/coordinate.dart';
import 'package:flutter_geomap_heatmap/src/geo_sampling.dart';

import '../geo_util/geo_util.dart';

/// Utility class for generating heatmap data.
class HeatmapUtil {
  final geoUtil = GeoUtil();

  static List<GeoSampling> generateHeatmap({required Map<String, dynamic> heatmapOptionMap}) {
    return HeatmapUtil().generateMap(heatmapOptionMap: heatmapOptionMap);
  }

  List<GeoSampling> generateMap({required Map<String, dynamic> heatmapOptionMap}) {
    final inicioTotal = DateTime.now();

    var t = DateTime.now();
    HeatmapOption heatmapOption = HeatmapOption.fromMap(heatmapOptionMap);
    log('Tempo fromMap: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    List<Coordinate> polygon = geoUtil.aumentarPoligono(heatmapOption.polygon);
    log('Tempo aumentarPoligono: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    List<List<Coordinate>> subPolygons = geoUtil.generateSubPolygons(polygon, heatmapOption.mapResolution);
    log('Tempo generateSubPolygons: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    subPolygons = geoUtil.removerSubPoligonosForaDoPrincipal(polygon, subPolygons);
    log('Tempo removerSubPoligonosForaDoPrincipal: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    List<List<List<Coordinate>>> separacao = geoUtil.separaComContatoNaLinhaPoligono(polygon, subPolygons);
    List<List<Coordinate>> subPoligonosComContato = separacao.first;
    List<List<Coordinate>> subPoligonosSemContato = separacao.last;
    log("🕒 Separa com e sem contato: ${DateTime.now().difference(t).inMilliseconds} ms");

    t = DateTime.now();
    subPoligonosComContato = geoUtil.cortarSobrasSubPoligonos(polygon, subPoligonosComContato);
    log("🕒 Cortar sobras: ${DateTime.now().difference(t).inMilliseconds} ms");

    subPolygons = subPoligonosComContato + subPoligonosSemContato;

    t = DateTime.now();
    subPolygons = geoUtil.cutExcessSubPolygons(polygon, subPolygons);
    log('Tempo cutExcessSubPolygons: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    List<GeoSampling> calculatedSamples = geoUtil.calculateIDW(heatmapOption.listSampling, subPolygons, heatmapOption.numberOfSubColors);
    log('Tempo calculateIDW: ${DateTime.now().difference(t).inMilliseconds} ms');

    // t = DateTime.now();
    // List<List<GeoSampling>> grupos = GeoSampling.agruparPorIntervalos(amostras: calculatedSamples, partes: 20);
    // List<GeoSampling> amostrasAgrupadas = [];

    // for (List<GeoSampling> grupo in grupos) {
    //   // Junta os polígonos de mesmo intervalo de valor
    //   List<List<Coordinate>> poligonos = grupo.map((amostra) => amostra.polygon).toList();
    //   List<List<Coordinate>> poligonosUnificados = geoUtil.uniaoPoligonsMesmoValor(poligonos);

    //   // Calcula a média dos valores do grupo
    //   double media = grupo.map((a) => a.value).reduce((a, b) => a + b) / grupo.length;

    //   // Cria nova GeoSampling para cada polígono unificado
    //   for (List<Coordinate> poligono in poligonosUnificados) {
    //     amostrasAgrupadas.add(
    //       GeoSampling(polygon: poligono, value: media),
    //     );
    //   }
    // }
    // log('Tempo agrupamento intervalos: ${DateTime.now().difference(t).inMilliseconds} ms');

    t = DateTime.now();
    calculatedSamples = geoUtil.generateColors(heatmapOption.min, heatmapOption.max, calculatedSamples, heatmapOption.colors);
    log('Tempo generateColors: ${DateTime.now().difference(t).inMilliseconds} ms');

    log('Tempo total: ${DateTime.now().difference(inicioTotal).inMilliseconds} ms');

    return calculatedSamples;
  }
}

class HeatmapOption {
  HeatmapOption({
    required this.polygon,
    required this.listSampling,
    required this.min,
    required this.max,
    this.mapResolution = 70,
    this.numberOfSubColors = 100,
    this.colors = const [
      Color(0xff02D91B),
      Color(0xffA3D902),
      Color(0xffD2D902),
      Color(0xffD95402),
      Color(0xffD10202),
    ],
  });

  List<Coordinate> polygon;
  List<GeoSampling> listSampling;
  double min;
  double max;
  int mapResolution;
  int numberOfSubColors;
  List<Color> colors;

  factory HeatmapOption.fromMap(Map<String, dynamic> map) {
    return HeatmapOption(
      polygon: List<Coordinate>.from(
        (map['polygon'] as List).map(
          (e) => Coordinate(lat: e['lat'], lng: e['lng']),
        ),
      ),
      listSampling: List<GeoSampling>.from(
        (map['listSampling'] as List).map(
          (e) => GeoSampling.fromMap(e), // Assuming GeoSampling has fromMap
        ),
      ),
      min: map['min'],
      max: map['max'],
      mapResolution: map['mapResolution'] ?? 70,
      numberOfSubColors: map['numberOfSubColors'] ?? 100,
      colors: List<Color>.from(
        (map['colors'] as List).map((colorValue) => Color(colorValue)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'polygon': polygon.map((e) => {'lat': e.lat, 'lng': e.lng}).toList(),
      'listSampling': listSampling.map((e) => e.toMap()).toList(),
      'min': min,
      'max': max,
      'mapResolution': mapResolution,
      'numberOfSubColors': numberOfSubColors,
      'colors': colors.map((color) => color.toARGB32()).toList(),
    };
  }
}
