import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class Work {
  int? seq;
  int category_seq;
  int? place_seq;
  String? checkdate;
  String content;
  String duedate;
  String? duetime;
  String? memo;
  Uint8List? image;
  int? customorder;
  int? mark;
  String? initdate;

  Work(
    {
      this.seq,
      required this.category_seq,
      this.place_seq,
      this.checkdate,
      required this.content,
      required this.duedate,
      this.duetime,
      this.memo,
      this.image,
      this.customorder,
      this.mark,
      this.initdate
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
    image = res['image'],
    customorder = res['customorder'],
    mark = res['mark'],
    initdate = res['initdate'];

}