class Place {
  int? seq;
  int work_seq;
  double lat;
  double lng;
  String name;

  Place(
    {
      this.seq,
      required this.work_seq,
      required this.lat,
      required this.lng,
      required this.name
    }
  );

  Place.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    work_seq = res['work_seq'],
    lat = res['lat'],
    lng = res['lng'],
    name = res['name'];
    
}