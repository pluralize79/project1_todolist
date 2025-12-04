import 'package:get/get.dart';

class MySnackbar {
  static error(String str){
    Get.snackbar(
      '오류', 
      str
    );
  }
}