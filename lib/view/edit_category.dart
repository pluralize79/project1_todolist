import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/util/my_snackbar.dart';
import 'package:project1_todolist/vm/database_handler.dart';

class EditCategory extends StatefulWidget {
  const EditCategory({super.key});

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
  late DatabaseHandler handler;
  late TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    titleController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('카테고리'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: handler.listCategorys(), 
        builder: (context, snapshot) {
          return snapshot.hasData && snapshot.data!.isNotEmpty
          ? ReorderableListView.builder(
            itemCount: snapshot.data!.length, 
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
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
                        titleController.text = snapshot.data![index].title;
                        if (item.seq == 1){ //기본 카테고리인지 확인 후 수정 막기
                          MySnackbar.error('경고','기본 카테고리는 수정할 수 없습니다.');
                        }else{
                          Categorys categorys = snapshot.data![index];
                          updatePopup(categorys);
                        }
                      },
                    ),
                    SlidableAction(
                      backgroundColor: ColorScheme.of(context).error,
                      foregroundColor: ColorScheme.of(context).onError,
                      label: '삭제',
                      onPressed: (context) async{
                        if (item.seq == 1){ //기본 카테고리인지 확인 후 삭제 막기
                          MySnackbar.error('경고','기본 카테고리는 삭제할 수 없습니다.');
                        }else{
                          await handler.deleteCategorys(snapshot.data![index]);
                          setState(() {});
                        }
                      },
                    )
                  ]
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorScheme.of(context).secondaryContainer,
                  ),
                  height: 50,
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          snapshot.data![index].title 
                        )
                      ),
                      Positioned.fill(
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
                      )
                    ],
                  ),
                ),
              );
            }, 
            onReorder: (oldIndex, newIndex) async{
              if (newIndex > oldIndex) newIndex--;
              final item = snapshot.data!.removeAt(oldIndex);
              snapshot.data!.insert(newIndex, item);
              await handler.updateCategoryOrder(snapshot.data!);

              setState(() {});
            },
          )
          : Center( // 로딩중
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        onPressed: () => insertPopup(),
        child: Icon(Icons.add_rounded),
      ),
    );
  } // build

  //카테고리 수정 팝업
  updatePopup(Categorys categorys){
    Get.dialog(
     AlertDialog(
      title: Text('카테고리 수정'),
      actions: [
        Column(
          children: [
            TextField(
              controller: titleController,
            ),
            TextButton(
              onPressed: () => updateAction(categorys), 
              child: Text('수정하기')
            )
          ],
        )
      ],
     )
    );
  }

  //카테고리 수정 액션
  updateAction(Categorys categorys) async{
    categorys.title = titleController.text;
    int result = await handler.updateCategorys(categorys);
    result == 0 
    ? MySnackbar.error('오류', '오류가 발생했습니다.') 
    : setState(() {});
    titleController.text = '';
    Get.back();
  }

  //카테고리 추가 팝업
  insertPopup(){
    Get.dialog(
     AlertDialog(
      title: Text('카테고리 추가'),
      actions: [
        Column(
          children: [
            TextField(
              controller: titleController,
              maxLines: 1,
              maxLength: 10,
            ),
            TextButton(
              onPressed: () => insertAction(), 
              child: Text('추가하기')
            )
          ],
        )
      ],
     )
    );
  }
  
  //카테고리 추가 액션
   insertAction() async{
    Categorys categorys = Categorys(
      title: titleController.text, 
      customorder: 0
    );
    int result = 0;
    result = await handler.addCategorys(categorys);
    if(result == 0){
      MySnackbar.error('오류','오류가 발생했습니다.');
    }
    titleController.text = "";
    Get.back();
    setState(() {});
   }

} // class