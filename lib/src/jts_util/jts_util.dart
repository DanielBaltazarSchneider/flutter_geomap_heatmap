import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter_geomap_heatmap/src/coordinate.dart';
import 'package:flutter_geomap_heatmap/src/polybool/polybool.dart';
import 'package:flutter_geomap_heatmap/src/polybool/types.dart';

class JTSUtil {
  List<List<Coordinate>> union(List<Coordinate> polygon1, List<Coordinate> polygon2) {
    RegionPolygon poly1 = RegionPolygon(
      regions: [
        polygon1.map((e) => jts.Coordinate(e.lng, e.lat)).toList(),
      ],
    );
    RegionPolygon poly2 = RegionPolygon(
      regions: [
        polygon2.map((e) => jts.Coordinate(e.lng, e.lat)).toList(),
      ],
    );
    var seg1 = PolyBool().segments(poly1);
    var seg2 = PolyBool().segments(poly2);
    CombinedSegmentLists comb = PolyBool().combine(seg1, seg2);
    var union = PolyBool().polygon(PolyBool().selectUnion(comb));
    List<List<jts.Coordinate>> cordU = union.regions;
    List<List<Coordinate>> uniao = [];
    for (List<jts.Coordinate> list in cordU) {
      uniao.add(list.map((e) => Coordinate(lat: e.y, lng: e.x)).toList());
    }
    return uniao;
  }

  List<List<Coordinate>> multiUnion(List<List<Coordinate>> polygons) {
    List<RegionPolygon> regions = polygons
        .map((element) => RegionPolygon(
              regions: [element.map((e) => jts.Coordinate(e.lng, e.lat)).toList()],
            ))
        .toList();

    var segments = PolyBool().segments(regions.first);
    for (var i = 1; i < polygons.length; i++) {
      var seg2 = PolyBool().segments(regions[i]);
      var comb = PolyBool().combine(segments, seg2);
      segments = PolyBool().selectUnion(comb);
    }
    var finalPolygon = PolyBool().polygon(segments);
    List<List<Coordinate>> uniao = [];
    for (List<jts.Coordinate> list in finalPolygon.regions) {
      uniao.add(list.map((e) => Coordinate(lat: e.y, lng: e.x)).toList());
    }
    return uniao;
  }

  List<List<Coordinate>> intersection(List<Coordinate> polygon1, List<Coordinate> polygon2) {
    RegionPolygon poly1 = RegionPolygon(
      regions: [polygon1.map((e) => jts.Coordinate(e.lng, e.lat)).toList()],
    );
    RegionPolygon poly2 = RegionPolygon(
      regions: [polygon2.map((e) => jts.Coordinate(e.lng, e.lat)).toList()],
    );
    var seg1 = PolyBool().segments(poly1);
    var seg2 = PolyBool().segments(poly2);
    CombinedSegmentLists comb = PolyBool().combine(seg1, seg2);
    var intersect = PolyBool().polygon(PolyBool().selectIntersect(comb));
    List<List<jts.Coordinate>> cordU = intersect.regions;
    List<List<Coordinate>> listFinal = [];
    for (List<jts.Coordinate> list in cordU) {
      listFinal.add(list.map((e) => Coordinate(lat: e.y, lng: e.x)).toList());
    }
    return listFinal;
  }
}
