import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1_todolist/view/edit_category.dart';
import 'package:project1_todolist/vm/database_handler.dart';

/* 
1) db에서 categorys 목록 받아와서 상단 탭으로 보이기 (동일 페이지, 다른 arguments)
2) appbar에 +버튼으로 카테고리 편집 페이지 이동
3) db에서 work 목록 받아와서 card로 보이기
4) work 탭할 시 하위 할일 목록 노출
5) slidable로 수정(페이지 이동), 삭제(바로 삭제)
*/

class ListWork extends StatefulWidget {
  const ListWork({super.key});

  @override
  State<ListWork> createState() => _ListWorkState();
}

class _ListWorkState extends State<ListWork> with SingleTickerProviderStateMixin{
  late DatabaseHandler handler;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();

    defaultset();
  }

  void defaultset() async{
    await handler.initializeDB();
    await handler.addDefaultCategorys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => Get.to(EditCategory())!.then((value) => setState(() {})), 
            icon: Icon(Icons.add_rounded)
          )
        ],
      ),
      body: FutureBuilder(
        future: handler.listCategorys(), 
        builder: (context, snapshot) {
          return snapshot.hasData && snapshot.data!.isNotEmpty
          ? SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {

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
    );
  } // build
} // class