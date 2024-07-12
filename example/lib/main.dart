import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_geomap_heatmap/flutter_geomap_heatmap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = Controller();
  final CameraPosition initialCameraPosition = const CameraPosition(target: LatLng(-25.045028, -54.373610), zoom: 16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Stack(
              children: [
                GoogleMap(
                  polygons: controller.polygons,
                  mapType: MapType.satellite,
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: (control) => controller.onMapCreated(control),
                ),
                Visibility(
                  visible: controller.isLoading,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withOpacity(0.9),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                )
              ],
            );
          }),
    );
  }
}

class Controller extends ChangeNotifier {
  /// Set of polygons composing the heatmap
  HashSet<Polygon> polygons = HashSet<Polygon>();

  /// Indicates if the map is being updated
  bool isLoading = true;

  /// Polygon defining the area of the field
  final List<LatLng> fieldPolygon = const [
    LatLng(-25.045404, -54.377299),
    LatLng(-25.042361, -54.374167),
    LatLng(-25.042712, -54.371191),
    LatLng(-25.043533, -54.371400),
    LatLng(-25.045949, -54.371226),
    LatLng(-25.046146, -54.372019),
    LatLng(-25.046373, -54.371731),
    LatLng(-25.050051, -54.374442),
    LatLng(-25.046648, -54.374488),
    LatLng(-25.046403, -54.375869),
    LatLng(-25.046532, -54.376067),
  ];

  /// Default values for heatmap generation
  List<GeoSampling> defaultValues = [
    GeoSampling(polygon: [Coordinate(lat: -25.043732, lng: -54.373879)], value: 5.5),
    GeoSampling(polygon: [Coordinate(lat: -25.043014, lng: -54.372542)], value: 4.5),
    GeoSampling(polygon: [Coordinate(lat: -25.044708, lng: -54.372013)], value: 3.1),
    GeoSampling(polygon: [Coordinate(lat: -25.046100, lng: -54.372710)], value: 0.0),
    GeoSampling(polygon: [Coordinate(lat: -25.045524, lng: -54.374573)], value: 1.1),
    GeoSampling(polygon: [Coordinate(lat: -25.045443, lng: -54.376420)], value: 0.23),
    GeoSampling(polygon: [Coordinate(lat: -25.048834, lng: -54.374062)], value: 0.0),
    GeoSampling(polygon: [Coordinate(lat: -25.045405, lng: -54.374990)], value: 2.0),
  ];

  /// Called when the map is created
  Future<void> onMapCreated(GoogleMapController controller) async {
    await updateMap();
    isLoading = false;
    notifyListeners();
  }

  /// Updates the map with the new heatmap
  Future<void> updateMap() async {
    HeatmapOption heatmapOption = HeatmapOption(
        polygon: fieldPolygon.map((e) => Coordinate(lat: e.latitude, lng: e.longitude)).toList(),
        listSampling: defaultValues,
        min: 1,
        max: 4.5,
        mapResolution: 60,
        numberOfSubColors: 100,
        colors: [
          const Color(0xffD10202),
          const Color(0xffD95402),
          const Color(0xffD2D902),
          const Color(0xffA3D902),
          const Color(0xff02D91B),
          const Color(0xffA3D902),
          const Color(0xffD2D902),
          const Color(0xffD95402),
          const Color(0xffD10202),
        ]);

    List<GeoSampling> calculatedValues = await Isolate.run(() => HeatmapUtil.generateHeatmap(heatmapOption: heatmapOption));
    polygons.addAll(createHeatMapPolygons(calculatedValues));
  }

  /// Creates polygons to represent the heatmap
  HashSet<Polygon> createHeatMapPolygons(List<GeoSampling> listSampling) {
    HashSet<Polygon> heatmapPolygons = HashSet<Polygon>();
    if (listSampling.isNotEmpty) {
      int index = 0;
      for (GeoSampling sampling in listSampling) {
        Polygon polygon = Polygon(
          polygonId: PolygonId("$index"),
          points: sampling.polygon.map((e) => LatLng(e.lat, e.lng)).toList(),
          strokeWidth: 0,
          strokeColor: Colors.transparent,
          fillColor: sampling.color.withOpacity(0.75),
          consumeTapEvents: false,
        );
        heatmapPolygons.add(polygon);
        index++;
      }
    }
    return heatmapPolygons;
  }
}
