import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/src/coordinate.dart';
import 'package:flutter_geomap_heatmap/src/geo_sampling.dart';

import '../jts_util/jts_util.dart';

class GeoUtil {
  /// Generates sub-polygons from a given polygon.
  ///
  /// [polygon]: The list of coordinates representing the main polygon.
  /// [subPolygons]: The number of sub-polygons to generate.
  List<List<Coordinate>> generateSubPolygons(List<Coordinate> polygon, int subPolygons) {
    List<List<Coordinate>> finalList = [];
    List<double> latList = findLatitudeMinMax(polygon);
    List<double> lngList = findLongitudeMinMax(polygon);

    double maxLat = latList.last;
    double minLat = latList.first;
    double maxLng = lngList.last;
    double minLng = lngList.first;

    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;

    double width = max(latDiff, lngDiff) / subPolygons;

    double border = width * 2;

    maxLat += border;
    minLat -= border;
    maxLng += border;
    minLng -= border;

    latDiff = maxLat - minLat;
    lngDiff = maxLng - minLng;

    width = max(latDiff, lngDiff) / subPolygons;

    for (int a = 0; a < subPolygons; a++) {
      for (int i = 0; i < subPolygons; i++) {
        List<Coordinate> polygonList = createSubPolygon(maxLat, maxLng, width, a, i);
        finalList.add(polygonList);
      }
    }
    return finalList;
  }

  /// Creates a sub-polygon based on given parameters.
  ///
  /// [maiorLat]: The maximum latitude value.
  /// [maiorLon]: The maximum longitude value.
  /// [tamanho]: The size of the sub-polygon.
  /// [a]: The index representing the row.
  /// [i]: The index representing the column.
  List<Coordinate> createSubPolygon(double maiorLat, double maiorLon, double tamanho, int a, int i) {
    List<Coordinate> polygonList = [];
    polygonList.add(Coordinate(lat: maiorLat - tamanho * (a + 1), lng: maiorLon - tamanho * i));
    polygonList.add(Coordinate(lat: maiorLat - tamanho * (a + 1), lng: maiorLon - tamanho * (i + 1)));
    polygonList.add(Coordinate(lat: maiorLat - tamanho * a, lng: maiorLon - tamanho * (i + 1)));
    polygonList.add(Coordinate(lat: maiorLat - tamanho * a, lng: maiorLon - tamanho * i));
    return polygonList;
  }

  /// Finds the maximum and minimum latitude values from a list of coordinates.
  ///
  /// [listGeoPos]: The list of coordinates.
  List<double> findLatitudeMinMax(List<Coordinate> listGeoPos) {
    List<double> listLat = listGeoPos.map((e) => e.lat).toList();
    listLat.sort((a, b) => a.compareTo(b));
    return [listLat.first, listLat.last];
  }

  /// Finds the maximum and minimum longitude values from a list of coordinates.
  ///
  /// [listGeoPos]: The list of coordinates.
  List<double> findLongitudeMinMax(List<Coordinate> listGeoPos) {
    List<double> listLng = listGeoPos.map((e) => e.lng).toList();
    listLng.sort((a, b) => a.compareTo(b));
    return [listLng.first, listLng.last];
  }

  /// Calculates the Inverse Distance Weighted (IDW) interpolation for a list of geo-samples.
  ///
  /// [geoSamplingList]: The list of geo-samples.
  /// [polygons]: The polygons to interpolate over.
  /// [numIntervals]: The number of intervals to divide the data into.
  List<GeoSampling> calculateIDW(List<GeoSampling> geoSamplingList, List<List<Coordinate>> polygons, int numIntervals) {
    try {
      List<GeoSampling> result = [];
      double minValue = findMinValue(geoSamplingList);
      double maxValue = findMaxValue(geoSamplingList);
      double interval = calculateInterval(minValue, maxValue, numIntervals);
      calculateValuesForPolygons(geoSamplingList, polygons, result);
      adjustValuesToIntervals(result, minValue, interval, numIntervals);
      return result;
    } catch (e, s) {
      print(e);
      print(s);
      return [];
    }
  }

  /// Finds the minimum value among a list of geo-samples.
  ///
  /// [geoSamplingList]: The list of geo-samples.
  double findMinValue(List<GeoSampling> geoSamplingList) {
    double minValue = double.infinity;
    for (GeoSampling geoSampling in geoSamplingList) {
      double value = geoSampling.value;
      minValue = min(minValue, value);
    }
    return minValue;
  }

  /// Finds the maximum value among a list of geo-samples.
  ///
  /// [geoSamplingList]: The list of geo-samples.
  double findMaxValue(List<GeoSampling> geoSamplingList) {
    double maxValue = double.negativeInfinity;
    for (GeoSampling geoSampling in geoSamplingList) {
      double value = geoSampling.value;
      maxValue = max(maxValue, value);
    }
    return maxValue;
  }

  /// Calculates the interval size for a given range and number of intervals.
  ///
  /// [minValue]: The minimum value in the range.
  /// [maxValue]: The maximum value in the range.
  /// [numIntervals]: The number of intervals to divide the range into.
  double calculateInterval(double minValue, double maxValue, int numIntervals) {
    double interval = (maxValue - minValue) / numIntervals;
    if (interval.isNaN) {
      interval = 1;
    }
    return interval;
  }

  /// Calculates values for polygons based on geo-sampling data.
  ///
  /// [geoSamplingList]: The list of geo-sampling data.
  /// [polygons]: The polygons to calculate values for.
  /// [resultado]: The list to store the calculated values.
  void calculateValuesForPolygons(List<GeoSampling> geoSamplingList, List<List<Coordinate>> polygons, List<GeoSampling> resultado) {
    for (List<Coordinate> coordinates in polygons) {
      if (coordinates.isNotEmpty) {
        double weightedSum = 0;
        double sumWeights = 0;

        for (GeoSampling geoSampling in geoSamplingList) {
          double distance = calculateDistance(coordinates[0], geoSampling.polygon.first);
          double weight = 1 / (distance * distance);
          weightedSum += weight * geoSampling.value;
          sumWeights += weight;
        }

        if (sumWeights > 0) {
          double calculatedValue = weightedSum / sumWeights;
          resultado.add(GeoSampling(polygon: coordinates, value: calculatedValue));
        }
      }
    }
  }

  /// Adjusts calculated values to fit into specified intervals.
  ///
  /// [resultado]: The list of calculated values to adjust.
  /// [minValue]: The minimum value in the range.
  /// [interval]: The interval size.
  /// [numIntervals]: The number of intervals.
  void adjustValuesToIntervals(List<GeoSampling> resultado, double minValue, double interval, int numIntervals) {
    for (GeoSampling geoSampling in resultado) {
      double value = (geoSampling.value - minValue) / interval;
      int intervalIndex = value.isNaN ? 1 : value.floor();
      intervalIndex = max(0, min(intervalIndex, numIntervals - 1));
      geoSampling.value = minValue + interval * intervalIndex;
    }
  }

  /// Calculates the Euclidean distance between two coordinates.
  ///
  /// [coordinate1]: The first coordinate.
  /// [coordinate2]: The second coordinate.
  double calculateDistance(Coordinate coordinate1, Coordinate coordinate2) {
    double latDiff = coordinate1.lat - coordinate2.lat;
    double lonDiff = coordinate1.lng - coordinate2.lng;
    return sqrt(latDiff * latDiff + lonDiff * lonDiff);
  }

  /// Generates colors for geo-sampling data based on specified color range.
  ///
  /// [min]: The minimum value in the data range.
  /// [max]: The maximum value in the data range.
  /// [geoSamplingList]: The list of geo-sampling data.
  /// [colors]: The list of colors to map the data to.
  List<GeoSampling> generateColors(double min, double max, List<GeoSampling> geoSamplingList, List<Color> colors) {
    for (GeoSampling polygon in geoSamplingList) {
      polygon.color = getColorFromValue(polygon.value, min, max, colors);
    }
    return geoSamplingList;
  }

  /// Calculates the color corresponding to a given value within a range.
  ///
  /// [value]: The value to map to a color.
  /// [minValue]: The minimum value in the range.
  /// [maxValue]: The maximum value in the range.
  /// [colors]: The list of colors to interpolate between.
  Color getColorFromValue(double value, double minValue, double maxValue, List<Color> colors) {
    if (colors.length < 2) {
      throw ArgumentError('The list of colors must contain at least two colors.');
    }

    if (value <= minValue) {
      return colors[0];
    }
    if (value >= maxValue) {
      return colors[colors.length - 1];
    }

    // Calculate the interpolation interval between the colors
    double interval = (maxValue - minValue) / (colors.length - 1);

    // Determine the position of the initial and final colors in the gradient
    int index1 = ((value - minValue) / interval).floor();
    int index2 = (index1 + 1).clamp(0, colors.length - 1);

    // Calculate the percentage within the interval for interpolation
    double percent = ((value - minValue) % interval) / interval;

    // Get the initial and final colors for interpolation
    Color color1 = colors[index1];
    Color color2 = colors[index2];

    // Interpolate the RGB components to get the color corresponding to the value
    int red = (color1.red + percent * (color2.red - color1.red)).round();
    int green = (color1.green + percent * (color2.green - color1.green)).round();
    int blue = (color1.blue + percent * (color2.blue - color1.blue)).round();

    // Ensure that the color values are in the range of 0 to 255
    red = red.clamp(0, 255);
    green = green.clamp(0, 255);
    blue = blue.clamp(0, 255);

    // Return the resulting color
    return Color.fromARGB(255, red, green, blue);
  }

  /// Cuts excess sub-polygons from a polygon using the JTS library.
  ///
  /// [polygon]: The main polygon to intersect with sub-polygons.
  /// [subPolygons]: The list of sub-polygons to intersect with the main polygon.
  List<List<Coordinate>> cutExcessSubPolygons(List<Coordinate> polygon, List<List<Coordinate>> subPolygons) {
    List<List<Coordinate>> cutPolygons = [];
    JTSUtil jtsUtil = JTSUtil();

    for (List<Coordinate> subPolygon in subPolygons) {
      List<List<Coordinate>> intersectedPolygons = jtsUtil.intersection(polygon, subPolygon);
      cutPolygons.addAll(intersectedPolygons);
    }
    return cutPolygons.isEmpty ? subPolygons : cutPolygons;
  }
}
