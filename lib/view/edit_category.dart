import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/view/my_snackbar.dart';
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
                      backgroundColor: ColorScheme.of(context).error,
                      label: '삭제',
                      onPressed: (context) async{
                        int nowSeq = await handler.seqCategorys(index);
                        if (nowSeq == 1){
                          MySnackbar.error('기본 카테고리는 삭제할 수 없습니다.');
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
                    border: Border(
                      bottom: BorderSide(color: ColorScheme.of(context).secondary, width: 2),
                    ),
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
                              child: Icon(Icons.menu)
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
        onPressed: () => insertPopup(),
        child: Icon(Icons.add_rounded),
      ),
    );
  } // build

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
      MySnackbar.error('오류가 발생했습니다.');
    }
    titleController.text = "";
    Get.back();
    setState(() {});
   }

} // class