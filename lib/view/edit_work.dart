import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/model/detail.dart';
import 'package:project1_todolist/model/place.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:project1_todolist/util/my_function.dart';
import 'package:project1_todolist/util/my_snackbar.dart';
import 'package:project1_todolist/vm/database_handler.dart';

class EditWork extends StatefulWidget {
  const EditWork({super.key});

  @override
  State<EditWork> createState() => _EditWorkState();
}

class _EditWorkState extends State<EditWork> {
  late DatabaseHandler handler;
  
  late TextEditingController contentController;
  late TextEditingController memoController;
  late TextEditingController detailController;
  late TextEditingController nameController;

  late int selectedCategorys;
  late List<String> detailList;
  late List<int> deleteDetailList;
  late List<Detail> visibleDetails;

  late DateTime today;
  late String selectedDate;
  late String selectedTime;

  XFile? imageFile;
  final ImagePicker picker = ImagePicker();
  late bool isPicExist;
  late bool isPicUpdated;

  late int selectedrepeat;

  late bool isPlaceExist;
  Position? currentPosition;
  double? latData; //latitude
  double? longData; //longitude
  String? firstName; //받아온 위치 이름
  int? placeSeq; //받아온 위치 시퀀스
  late MapController mapController;

  Work value = Get.arguments ?? "___";


  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    contentController = TextEditingController();
    memoController = TextEditingController();
    detailController = TextEditingController();
    nameController = TextEditingController();

    selectedCategorys = value.category_seq;
    detailList = [];
    deleteDetailList = [];
    visibleDetails = [];

    today = DateTime.now();
    selectedDate = value.duedate;
    selectedTime = value.duetime == null ? today.toString().substring(11,16) : value.duetime!;

    isPicExist = value.image == null ? false : true;
    isPicUpdated = false;

    selectedrepeat = 0;
    
    isPlaceExist = false;
    isFirstPlaceExist();
    mapController = MapController();

    contentController.text = value.content;
    memoController.text = value.memo==null ? "" : value.memo!;
  }

  //페이지 기본 데이터 받아오기
  Future<({
    List<Categorys> categories,
    List<Detail> details,
  })> loadPageData() async {
    //리스트 데이터 받기
    final categories = await handler.listCategorys();
    final details = await handler.listDetail(value.seq!);

    return (
      categories: categories,
      details: details,
    );
  }  

  //장소가 있는지 받아오기
  Future<void> isFirstPlaceExist() async {
    final list = await handler.listPlace(value.seq!);
    isPlaceExist = list.isNotEmpty;
    if(isPlaceExist){
      latData = list[0].lat;
      longData = list[0].lng;
      firstName = list[0].name;
      placeSeq = list[0].seq;
      nameController.text = firstName==null ? "" : firstName!;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('작업 수정'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: FutureBuilder( // 카테고리 버튼
            future: loadPageData(), 
            builder: (context, snapshot) {
              if(!snapshot.hasData){
                return Center(
                  child: CircularProgressIndicator()
                );
              }else{
                final categories = snapshot.data!.categories;
                final details = snapshot.data!.details;
                if (visibleDetails.isEmpty) {
                    visibleDetails = List.from(details);
                  }
                return Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          Categorys item = categories[index];
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
                              child: Text(categories[index].title),
                            ),
                          );
                        },
                      ),
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
                              if(currentPosition == null && isPlaceExist == false){
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
                              ? value.image == null ? Text("이미지 없음"): Image.memory( value.image!)
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
                    Column( // 기존 하위항목 표시
                      children: [
                        ...visibleDetails.map((e) {
                          return Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Icon(Icons.check_box_outline_blank_outlined),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    e.content,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  deleteDetailList.add(e.seq!);
                                  visibleDetails.remove(e);
                                  setState(() {});
                                }
                              )
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    Column( // 새 하위항목 표시
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
                          updateAction();
                        }, 
                        child: Text('작업 수정하기')
                      ),
                    )
                  ],
                );
              }
            },
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
  }

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
      initialDate: DateTime.parse(value.duedate),
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
      initialTime: value.duetime==null ? TimeOfDay.now() : MyFunction.parseTime(value.duetime!)
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
      isPicUpdated = true;
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
                      latlng.LatLng centerposition = mapController.camera.center;
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

  //작업 수정하기 액션
  Future updateAction() async{
    // File Type을 Byte Type으로 변환하기
    Uint8List? getImage;
    Work workInsert;
    if(imageFile != null){ // 사진이 추가되었으면 사진 추가
      File imageFile1 = File(imageFile!.path);
       getImage = await imageFile1.readAsBytes();
      //이미지 있는 작업
      workInsert = Work(
        seq: value.seq,
        category_seq: selectedCategorys,  
        content: contentController.text, 
        duedate: selectedDate, 
        duetime: selectedTime,
        repeat: selectedrepeat, 
        memo: memoController.text, 
        image: getImage, 
      );
    }else if(imageFile == null && isPicExist){
      workInsert = Work(
        seq: value.seq,
        category_seq: selectedCategorys,  
        content: contentController.text, 
        duedate: selectedDate, 
        duetime: selectedTime,
        repeat: selectedrepeat, 
        memo: memoController.text, 
        image: value.image, 
      );
    }else{
      workInsert = Work(
        seq: value.seq,
        category_seq: selectedCategorys,  
        content: contentController.text, 
        duedate: selectedDate, 
        duetime: selectedTime,
        repeat: selectedrepeat, 
        memo: memoController.text, 
        image: null,
      );
    }

    int check = await handler.updateWork(workInsert);
    if(check == 0){
      MySnackbar.error('오류', '작업 수정 중 오류가 발생했습니다.');
    }else{
      Get.back();
    }

    //장소가 바뀌었으면 장소 수정
    if(placeSeq == null && isPlaceExist){ //원래 없었고 생겼으면 추가
      Place place = Place(
        work_seq: value.seq!,
        lat: latData!, 
        lng: longData!, 
        name: nameController.text
      );
      int result = await handler.addPlace(place);
      if(result == 0){
        MySnackbar.error('오류', '위치 삽입 중 오류가 발생했습니다.');
      }
    }else if(placeSeq != null && !isPlaceExist){ //삭제되었으면 삭제
      await handler.deletePlace(placeSeq!);
    }else if(placeSeq != null && isPlaceExist){ //수정되었으면 수정
      Place place = Place(
        seq: placeSeq,
        work_seq: value.seq!,
        lat: latData!, 
        lng: longData!, 
        name: nameController.text
      );
      await handler.updatePlace(place);
    }

    if(deleteDetailList.isNotEmpty){ //하위 항목 삭제되었으면 삭제 
      await handler.deleteDetail(deleteDetailList);
    }

    if(detailList != []){ //하위 항목이 추가되었으면 하위 항목 추가
      List<Detail> details = [];
      for(String data in detailList){
        Detail detail = Detail(
          work_seq: value.seq!,  
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
}