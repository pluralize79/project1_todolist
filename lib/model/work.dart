import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class Work {
  int? seq;
  int category_seq;
  int place_seq;
  String checkdate;
  String content;
  String duedate;
  String duetime;
  String memo;
  Uint8List image;

  Work(
    {
      this.seq,
      required this.category_seq,
      required this.place_seq,
      required this.checkdate,
      required this.content,
      required this.duedate,
      required this.duetime,
      required this.memo,
      required this.image
    }
  );

  Work.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    category_seq = res['category_seq'],
    place_seq = res['place_seq'],
    checkdate = res['checkdate'],
    content = res['content'],
    duedate = res['duedate'],
    duetime = res['duetime'],
    memo = res['memo'],
    image = res['image'];

}