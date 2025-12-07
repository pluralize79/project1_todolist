import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:project1_todolist/view/add_work.dart';
import 'package:project1_todolist/view/edit_category.dart';
import 'package:project1_todolist/view/edit_work.dart';
import 'package:project1_todolist/view/page_work.dart';
import 'package:project1_todolist/vm/database_handler.dart';

/* 
1) db에서 categorys 목록 받아와서 상단 탭으로 보이기 (동일 페이지, 다른 arguments)
  1-1) 눌린 버튼 seq 변수를 만들어서 선별적으로 작업 보여주기 (0은 전체 보기) 
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
  late int selectedCategorys;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    selectedCategorys = 0;

    loadPageData();
  }

  //페이지 기본 데이터 받아오기
  Future<({
    List<Categorys> categories,
    List<Work> works,
  })> loadPageData() async {
    //DB 초기화
    await handler.initializeDB();

    //기본 카테고리 삽입
    await handler.addDefaultCategorys();

    //리스트 데이터 받기
    final categories = await handler.listCategorys();
    final works = await handler.listWork(selectedCategorys);

    return (
      categories: categories,
      works: works,
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder(
              future: loadPageData(), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!.categories;
                final works = snapshot.data!.works;
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      SizedBox( //카테고리 버튼 목록
                        height: 30,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedCategorys == categories[index].seq!;
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  backgroundColor: isSelected ? ColorScheme.of(context).primary : ColorScheme.of(context).surface,
                                  foregroundColor: isSelected ? ColorScheme.of(context).onPrimary : ColorScheme.of(context).onSurface
                                ),
                                onPressed: () {
                                  if(selectedCategorys == categories[index].seq!){
                                    selectedCategorys = 0;
                                  }else{
                                    selectedCategorys = categories[index].seq!;
                                  }
                                  setState(() {});
                                },
                                child: Text(categories[index].title),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height/1.5,
                          child: ReorderableListView.builder( //작업 목록
                            itemCount: works.length, 
                            itemBuilder: (context, index) {
                              final item = works[index];
                              return Slidable(
                                key: ValueKey(item.seq),
                                endActionPane: ActionPane(
                                  motion: BehindMotion(), 
                                  children: [
                                    SlidableAction(
                                      backgroundColor: ColorScheme.of(context).secondary,
                                      foregroundColor: ColorScheme.of(context).onSecondary,
                                      label: '수정',
                                      onPressed: (context) async{
                                        Get.to(
                                          EditWork(),
                                          arguments: works[index]
                                        )!.then((value) => setState(() {}));
                                      },
                                    ),
                                    SlidableAction(
                                      backgroundColor: ColorScheme.of(context).error,
                                      foregroundColor: ColorScheme.of(context).onError,
                                      label: '삭제',
                                      onPressed: (context) async{
                                        await handler.deleteWork(works[index]);
                                        setState(() {});
                                      },
                                    )
                                  ]
                                ),
                                child: GestureDetector(
                                  onTap: (){
                                    Get.to(
                                      PageWork(),
                                      arguments: works[index].seq
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorScheme.of(context).secondaryContainer,
                                    ),
                                    height: 50,
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Text(
                                            works[index].content 
                                          )
                                        ),
                                        Visibility(
                                          visible: selectedCategorys == 0 ? true : false,
                                          child: Positioned.fill(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: ReorderableDragStartListener(
                                                  index: index,
                                                  child: Icon(Icons.drag_handle)
                                                ),
                                              )
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }, 
                            onReorder: (oldIndex, newIndex) async{
                              if (newIndex > oldIndex) newIndex--;
                              final item = works.removeAt(oldIndex);
                              works.insert(newIndex, item);
                              await handler.updateWorkOrder(works);
                          
                              setState(() {});
                            },
                          ),
                        ),
                      )
                    ]
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        onPressed: () => Get.to(AddWork())!.then((value) => setState(() {})),
        child: Icon(Icons.add_rounded),
      ),
    );
  } // build
} // class