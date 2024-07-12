import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/src/coordinate.dart';
import 'package:flutter_geomap_heatmap/src/geo_sampling.dart';

import '../geo_util/geo_util.dart';

/// Utility class for generating heatmap data.
class HeatmapUtil {
  final geoUtil = GeoUtil();

  static List<GeoSampling> generateHeatmap({required HeatmapOption heatmapOption}) {
    return HeatmapUtil().generateMap(heatmapOption: heatmapOption);
  }

  List<GeoSampling> generateMap({required HeatmapOption heatmapOption}) {
    List<List<Coordinate>> subPolygons = geoUtil.generateSubPolygons(heatmapOption.polygon, heatmapOption.mapResolution);
    subPolygons = geoUtil.cutExcessSubPolygons(heatmapOption.polygon, subPolygons);

    List<GeoSampling> calculatedSamples = geoUtil.calculateIDW(heatmapOption.listSampling, subPolygons, heatmapOption.numberOfSubColors);
    calculatedSamples = geoUtil.generateColors(heatmapOption.min, heatmapOption.max, calculatedSamples, heatmapOption.colors);
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
}
