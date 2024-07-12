import 'package:flutter_geomap_heatmap/flutter_geomap_heatmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Teste de geração de sub-polígonos', () {
    GeoUtil geoUtil = GeoUtil();
    List<Coordinate> polygon = [
      Coordinate(lat: 0, lng: 0),
      Coordinate(lat: 0, lng: 1),
      Coordinate(lat: 1, lng: 1),
      Coordinate(lat: 1, lng: 0),
    ];
    List<List<Coordinate>> subPolygons = geoUtil.generateSubPolygons(polygon, 4);
    expect(subPolygons.length, 16);
  });

  test('Teste de cálculo do intervalo', () {
    GeoUtil geoUtil = GeoUtil();
    double minValue = 0;
    double maxValue = 100;
    int numIntervals = 5;
    double interval = geoUtil.calculateInterval(minValue, maxValue, numIntervals);
    expect(interval, 20);
  });

  test('Teste de cálculo da distância euclidiana', () {
    GeoUtil geoUtil = GeoUtil();
    Coordinate coordinate1 = Coordinate(lat: 0, lng: 0);
    Coordinate coordinate2 = Coordinate(lat: 3, lng: 4);
    double distance = geoUtil.calculateDistance(coordinate1, coordinate2);
    expect(distance, 5);
  });

  test('Teste de ajuste de valores para intervalos', () {
    GeoUtil geoUtil = GeoUtil();
    List<GeoSampling> geoSamplingList = [
      GeoSampling(polygon: [], value: 0),
      GeoSampling(polygon: [], value: 25),
      GeoSampling(polygon: [], value: 50),
      GeoSampling(polygon: [], value: 75),
      GeoSampling(polygon: [], value: 100),
    ];
    double minValue = 0;
    double interval = 20;
    int numIntervals = 5;
    geoUtil.adjustValuesToIntervals(geoSamplingList, minValue, interval, numIntervals);
    expect(geoSamplingList[0].value, 0);
    expect(geoSamplingList[1].value, 20);
    expect(geoSamplingList[2].value, 40);
    expect(geoSamplingList[3].value, 60);
    expect(geoSamplingList[4].value, 80);
  });
}
