import 'package:get/get.dart';

class MySnackbar {
  static error(String str1, String str2){
    Get.snackbar(
      str1, 
      str2
    );
  }
}