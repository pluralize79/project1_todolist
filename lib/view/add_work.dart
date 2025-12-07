import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:latlong2/latlong.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/model/detail.dart';
import 'package:project1_todolist/model/place.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:project1_todolist/util/my_snackbar.dart';
import 'package:project1_todolist/vm/database_handler.dart';

/* 
1) 카테고리 버튼으로 카테고리 seq값 받아오기
2) content, memo는 Textfield로 받아오기
3) 하위항목은 플러스 버튼을 눌러서 팝업으로 추가, x버튼으로 바로 삭제, 연필로 수정
4) date picker와 time picker로 날짜 시간 받아오기
5) image picker로 이미지 받아오기
6) 지도로 위도 경도 받아오기
*/

class AddWork extends StatefulWidget {
  const AddWork({super.key});

  @override
  State<AddWork> createState() => _AddWorkState();
}

class _AddWorkState extends State<AddWork> {
  late DatabaseHandler handler;
  
  late TextEditingController contentController;
  late TextEditingController memoController;
  late TextEditingController detailController;
  late TextEditingController nameController;

  late int selectedCategorys;
  late List<String> detailList;

  late DateTime today;
  late String selectedDate;
  late String selectedTime;

  XFile? imageFile;
  final ImagePicker picker = ImagePicker();
  late bool isPicExist;

  late int selectedrepeat;

  late bool isPlaceExist;
  Position? currentPosition;
  double? latData; //latitude
  double? longData; //longitude
  late MapController mapController;


  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    contentController = TextEditingController();
    memoController = TextEditingController();
    detailController = TextEditingController();
    nameController = TextEditingController();

    selectedCategorys = 1;
    detailList = [];

    today = DateTime.now();
    selectedDate = today.toString().substring(0,10);
    selectedTime = today.toString().substring(11,16);

    isPicExist = false;

    selectedrepeat = 0;
    
    isPlaceExist = false;
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('작업 추가'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              FutureBuilder( // 카테고리 버튼
                future: handler.listCategorys(), 
                builder: (context, snapshot) {
                  return snapshot.hasData && snapshot.data!.isNotEmpty
                  ? SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Categorys item = snapshot.data![index];
                        bool isSelected = selectedCategorys == item.seq; //선택된 카테고리인가?
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: isSelected ? ColorScheme.of(context).primary : ColorScheme.of(context).surface,
                              foregroundColor: isSelected ? ColorScheme.of(context).onPrimary : ColorScheme.of(context).onSurface
                            ),
                            onPressed: () {
                              selectedCategorys = item.seq!;
                              setState(() {});
                            },
                            child: Text(snapshot.data![index].title),
                          ),
                        );
                      },
                    ),
                  )
                  : Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder()
                  ),
                  maxLines: 1,
                  maxLength: 20,
                ),
              ),
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  labelText: '메모',
                  border: OutlineInputBorder()
                ),
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
              ),
              ElevatedButton( //마감일 버튼
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width-50,40)
                ),
                onPressed: (){
                  dispDatePicker();
                }, 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month),
                    Text(' 마감일 : $selectedDate'),
                  ],
                )
              ),
              ElevatedButton( //마감시간 버튼
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width-50,40)
                ),
                onPressed: (){
                  dispTimePicker();
                }, 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time),
                    Text(' 마감 시간 : $selectedTime'),
                  ],
                )
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                      child: ElevatedButton( //이미지 추가 버튼
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(MediaQuery.of(context).size.width/2-30,40)
                        ),
                        onPressed: (){
                          getImageFromGallery(ImageSource.gallery);
                        }, 
                        child: Row(
                          children: [
                            Icon(Icons.image),
                            Text(' 이미지 선택'),
                          ],
                        )
                      ),
                    ),
                    ElevatedButton( //장소 추가 버튼
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(MediaQuery.of(context).size.width/2-30,40),
                        backgroundColor: isPlaceExist ? ColorScheme.of(context).primary : null
                      ),
                      onPressed: () async{
                        showLoadingDialog();
                        if(currentPosition == null){
                          await checkLocationPermission();
                          await getCurrentLocation();
                        }
                        Get.back();
                        if(latData == null || longData == null) {
                          MySnackbar.error('오류', '현재 위치를 가져올 수 없습니다.');
                          return;
                        }
                        mapPickPopup();
                      }, 
                      child: Row(
                        children: [
                          Icon(
                            Icons.place,
                            color: isPlaceExist ? ColorScheme.of(context).onPrimary : null,
                          ),
                          Text(
                            ' 장소 선택',
                            style: TextStyle(
                              color: isPlaceExist ? ColorScheme.of(context).onPrimary :null
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: isPicExist,
                child: Stack(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width-40,
                      height: 200,
                      child: Center(
                        child: imageFile == null
                        ? Text('Image is not selected')
                        : Image.file(File(imageFile!.path)),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          imageFile = null;
                          isPicExist = false;
                          setState(() {});
                        },
                        icon: Icon(Icons.close),
                      )
                    )
                  ] 
                ),
              ),
              Column( // 하위항목 표시
                children: [
                  ...detailList.map((item) {
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                          child: Icon(Icons.check_box_outline_blank_outlined),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15,0,0,0),
                            child: Text(item, softWrap: true,),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => deleteDetail(item),
                        )
                      ],
                    );
                  }),
                ],
              ),
              IconButton( 
                onPressed: () {
                  addDetailPopup();
                }, 
                icon: Icon(Icons.add_rounded)
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: () {
                    insertAction();
                  }, 
                  child: Text('작업 추가하기')
                ),
              )
            ],
          ),
        ),
      ),
    );
  } // build

  //하위 항목 입력 팝업
  addDetailPopup(){
    Get.dialog(
     AlertDialog(
      title: Text('하위 항목 추가'),
      actions: [
        Column(
          children: [
            TextField(
              controller: detailController,
              maxLines: 1,
              maxLength: 50,
            ),
            TextButton(
              onPressed: () {
                addDetail();
                Get.back();
              }, 
              child: Text('추가하기')
            )
          ],
        )
      ],
     )
    );
  } // build
  
  //하위 항목 추가
  addDetail(){
    detailList.add(detailController.text);
    detailController.text = "";
    setState(() {});
  }

  //하위 항목 삭제
  deleteDetail(String str){
    detailList.remove(str);
    setState(() {});
  }

  //날짜 선택기 띄우기
  dispDatePicker()async{
    // 날짜 범위
    int firstYear = today.year - 1;
    int lastYear = today.year + 5;

    final selectedDateText = await showDatePicker(
      context: context, 
      initialDate: today,
      firstDate: DateTime(firstYear), 
      lastDate: DateTime(lastYear),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if(selectedDateText != null){
      selectedDate = selectedDateText.toString().substring(0,10);
    }
      setState(() {});
    }

  //시간 선택기 띄우기
  void dispTimePicker() async{
    final selectedTimeText = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now()
    );
    if(selectedTimeText != null){
      selectedTime = selectedTimeText.toString().substring(10,15);
    }
    setState(() {});
  }

  //이미지 선택
  getImageFromGallery(ImageSource imageSource) async{
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if(pickedFile == null){
      return;
    }else{
      imageFile = XFile(pickedFile.path);
      isPicExist = true;
      setState(() {});
    }
  }

  //위치 권한 허용받기
  checkLocationPermission() async{
    LocationPermission permission = await Geolocator.checkPermission();
    
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
    }

    if(permission == LocationPermission.deniedForever){
      return;
    }
  }
  
  //현재 위치 받아오기
  getCurrentLocation() async{
    Position position = await Geolocator.getCurrentPosition();
    latData = position.latitude;
    longData = position.longitude;
    setState(() {});
  }

  //지도 팝업창 띄우기
  mapPickPopup(){
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: Text('장소 추가'),
        actions:[
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 300,
            child: Stack(
              children:[
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: latlng.LatLng(latData!,longData!),
                    initialZoom: 17.0,
                    onMapEvent: (event) { //지도 중앙 위치 받아오기
                      LatLng centerposition = mapController.camera.center;
                      latData = centerposition.latitude;
                      longData = centerposition.longitude;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", //띄어쓰기 안됨
                      userAgentPackageName: "com.tj.gpsmapapp",
                    ),
                  ]
                ),
                Center(
                  child: Icon(Icons.place, size: 40, color: ColorScheme.of(context).error),
                )
              ] 
            ),
            
          ),
          TextField(
            controller: nameController,
            maxLines: 1,
            maxLength: 20,
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    isPlaceExist = true;
                    Get.back(); 
                    setState(() {});
                  }, 
                  child: Text('선택')
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      latData = null;
                      longData = null;
                      nameController.text = "";
                      isPlaceExist = false;
                      Get.back();
                      setState(() {});
                    }, 
                    child: Text('위치 삭제')
                  ),
                ),
              ],
            ),
          ),
        ]
      )
    );
  }

  //로딩 팝업창
  void showLoadingDialog() {
    Get.dialog(
      barrierDismissible: false,
      Center(
        child: CircularProgressIndicator()
      )
    );
  }

  //작업 추가하기 액션
  Future insertAction() async{
    // File Type을 Byte Type으로 변환하기
    Uint8List? getImage;
    if(imageFile != null){ // 사진이 추가되었으면 사진 추가
      File imageFile1 = File(imageFile!.path);
       getImage = await imageFile1.readAsBytes();
    }

    //작업 추가
    var workInsert = Work(
      category_seq: selectedCategorys,  
      content: contentController.text, 
      duedate: selectedDate, 
      duetime: selectedTime,
      repeat: selectedrepeat, 
      memo: memoController.text, 
      image: getImage, 
    );
    int check = await handler.addWork(workInsert);
    if(check == 0){
      MySnackbar.error('오류', '작업 추가 중 오류가 발생했습니다.');
    }else{
      Get.back();
    }

    if(isPlaceExist){ //위치가 선택되었으면 위치 추가
      Place place = Place(
        work_seq: check,
        lat: latData!, 
        lng: longData!, 
        name: nameController.text
      );
      int result = await handler.addPlace(place);
      if(result == 0){
        MySnackbar.error('오류', '위치 삽입 중 오류가 발생했습니다.');
      }
    }    

    if(detailList != []){ //하위 항목이 추가되었으면 하위 항목 추가
      List<Detail> details = [];
      for(String data in detailList){
        Detail detail = Detail(
          work_seq: check,  
          content: data, 
        );
        details.add(detail);
      }
      int result = await handler.addDetail(details);
      if (result == 0 && detailList.isNotEmpty){
        MySnackbar.error('오류', '하위 항목 삽입 중 오류가 발생했습니다.');
      }
    }

  }

  

} // class