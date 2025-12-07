import 'package:flutter/material.dart';

class MyFunction {

  //DB의 time을 TimeOfDay로 변환
  static TimeOfDay parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

}