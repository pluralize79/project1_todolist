import 'package:path/path.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {

  //Connection
  Future<Database> initializeDB() async{
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'todolist.db'),
      onCreate: (db, version) async{
        await db.execute(
          """
          create table work
          (
            seq integer primary key autoincrement,
            category_seq integer,
            place_seq integer,
            checkdate text,
            content text,
            duedate text,
            duetime text,
            repeat text,
            memo text,
            image blob,
            customorder integer,
            mark integer,
            initdate text
          )
          """
        );
        await db.execute(
          """
          create table categorys
          (
            seq integer primary key autoincrement,
            title text,
            customorder integer
          )
          """
        );
        await db.execute(
          """
          create table detail
          (
            seq integer primary key autoincrement,
            work_seq integer,
            checked integer,
            content text,
            customorder integer
          )
          """
        );
        await db.execute(
          """
          create table place
          (
            seq integer primary key autoincrement,
            lat real,
            lng real,
            name text
          )
          """
        );
        await db.execute(
          """
          create table settings
          (
            themecolor integer,
            darkmode integer
          )
          """
        );
        await db.execute(
          """
          create table alarm
          (
            seq integer primary key autoincrement,
            work_seq integer,
            alarmtime text
          )
          """
        );
      },
      version: 1
    );
  }

  //카테고리 리스트
  Future<List<Categorys>> listCategorys() async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      """
      select * from categorys
      order by customorder
      """
    );
    return queryResult.map((e) => Categorys.fromMap(e)).toList();
  }

  //카테고리 기본 데이터 추가 (데이터 없을 때만)
  Future<int> addDefaultCategorys() async{
    int result = 0;
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from categorys"
    );
    if(queryResult.isNotEmpty){ //이미 카테고리가 있으면 삽입 없이 1 반환
      return 1;
    }else{
      //다음 customorder값 확인
      var maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from categorys"
      );
      var nextOrder = maxOrderResult.first['next'];
      //기본 카테고리(작업) 삽입
      result = await db.rawInsert(
        """
          insert into categorys
          (title, customorder)
          values
          (?, ?)
        """,
        ['작업',nextOrder]
      );
      if(result == 0) return 0;

      //다음 customorder값 확인
      maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from categorys"
      );
      nextOrder = maxOrderResult.first['next'];
      //기본 카테고리(약속) 삽입
      result = await db.rawInsert(
        """
          insert into categorys
          (title, customorder)
          values
          (?, ?)
        """,
        ['약속',nextOrder]
      );
      if(result == 0) return 0;

      //기본 카테고리(기념일) 삽입
      maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from categorys"
      );
      nextOrder = maxOrderResult.first['next'];
      //
      result = await db.rawInsert(
        """
          insert into categorys
          (title, customorder)
          values
          (?, ?)
        """,
        ['기념일',nextOrder]
      );
      return result;
    }
  }

  //카테고리 순서 바꾸기
  Future<void> updateCategoryOrder(List<Categorys> list) async {
    final Database db = await initializeDB();
    for (int i = 0; i < list.length; i++) {
      await db.rawUpdate(
        '''
        update categorys
        set customorder = ?
        where seq = ?
        ''',
        [i, list[i].seq],
      );
    }
  }

  //카테고리 추가
  Future<int> addCategorys(Categorys categorys) async{
    int result = 0;
    final Database db = await initializeDB();
    //다음 customorder값 확인
      var maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from categorys"
      );
      var nextOrder = maxOrderResult.first['next'];
    result = await db.rawInsert(
      """
        insert into categorys
        (title, customorder)
        values
        (?, ?)
      """,
      [categorys.title, nextOrder]
    );
    return result;
  }

  //카테고리 수정
  Future<int> updateCategorys(Categorys categorys) async{
    final Database db = await initializeDB();
    int result = 0;
    result = await db.rawUpdate(
      """
      update categorys
      set title = ?
      where seq = ?
      """,
      [categorys.title, categorys.seq]
    );
    return result;
  }

  //카테고리 삭제
  Future<void> deleteCategorys(Categorys categorys) async{
    final Database db = await initializeDB();
    await db.rawUpdate(
    """
      delete from categorys
      where seq = ?
    """,
    [categorys.seq]
    );
    await db.rawUpdate(
      '''
      update categorys
      set customorder = customorder - 1
      where customorder > ?
      ''',
      [categorys.customorder],
    );
  }


  // 작업 추가
  Future<int> addWork(Work work) async{
    int result = 0;
    final Database db = await initializeDB();
    //다음 customorder값 확인
      var maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from work"
      );
      var nextOrder = maxOrderResult.first['next'];
    result = await db.rawInsert(
      """
        insert into work
        (category_seq, place_seq, checkdate, content, duedate, duetime, memo, image, customorder, mark, initdate)
        values
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, date('now'))
      """,
      [
        work.category_seq,
        work.place_seq,
        work.checkdate,
        work.content,
        work.duedate,
        work.duetime,
        work.memo,
        work.image,
        nextOrder,
        work.mark,
      ]
    );
    return result;
  }

}