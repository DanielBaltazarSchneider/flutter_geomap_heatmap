class Coordinate {
  double lat;
  double lng;

  Coordinate({required this.lat, required this.lng});

  @override
  String toString() {
    return "(lat: $lat, lng: $lng)";
  }

  @override
  bool operator ==(Object other) {
    if (other is! Coordinate) return false;
    if (lat != other.lat) return false;
    if (lng != other.lng) return false;
    return true;
  }

  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + lat.hashCode;
    result = 37 * result + lng.hashCode;
    return result;
  }
}
