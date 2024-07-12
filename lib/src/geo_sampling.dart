import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/src/coordinate.dart';

class GeoSampling {
  GeoSampling({required this.polygon, required this.value, this.color = Colors.transparent});

  List<Coordinate> polygon;
  double value;
  Color color;
}
