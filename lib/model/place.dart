class Place {
  int? seq;
  double lat;
  double lng;
  String name;

  Place(
    {
      this.seq,
      required this.lat,
      required this.lng,
      required this.name
    }
  );

  Place.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    lat = res['lat'],
    lng = res['lng'],
    name = res['name'];
    
}