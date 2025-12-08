import 'package:path/path.dart';
import 'package:project1_todolist/model/categorys.dart';
import 'package:project1_todolist/model/detail.dart';
import 'package:project1_todolist/model/place.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {

  //Connection
  Future<Database> initializeDB() async{
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'todolist.db'),
      onConfigure: (db) async { //매 연결마다 외래키 활성화
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async{
        await db.execute(
          """
          create table work
          (
            seq integer primary key autoincrement,
            category_seq integer,
            checkdate text,
            content text,
            duedate text,
            duetime text,
            repeat integer,
            memo text,
            image blob,
            customorder integer,
            mark integer,
            initdate text,

            foreign key (category_seq)
            references categorys(seq)
            on delete cascade
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
            customorder integer,

            foreign key (work_seq)
            references work(seq)
            on delete cascade            
          )
          """
        );
        await db.execute(
          """
          create table place
          (
            seq integer primary key autoincrement,
            work_seq integer,
            lat real,
            lng real,
            name text,

            foreign key (work_seq)
            references work(seq)
            on delete cascade             
          )
          """
        );
      },
      version: 1
    );
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
    await db.rawUpdate(//카테고리 삭제
    """
      delete from categorys
      where seq = ?
    """,
    [categorys.seq]
    );
    await db.rawUpdate( //나머지 카테고리의 순서 당기기
      '''
      update categorys
      set customorder = customorder - 1
      where customorder > ?
      ''',
      [categorys.customorder],
    );
  }

  //작업 삭제
  Future<void> deleteWork(Work work) async{
    final Database db = await initializeDB();
    await db.rawUpdate(//작업 삭제
    """
      delete from work
      where seq = ?
    """,
    [work.seq]
    );
    await db.rawUpdate( //나머지 작업의 순서 당기기
      '''
      update work
      set customorder = customorder - 1
      where customorder > ?
      ''',
      [work.customorder],
    );
  }

  //작업 리스트
  Future<List<Work>> listWork(int cat) async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult;
    if(cat==0){ //선택 안 되어 있을 때
      queryResult = await db.rawQuery(
        """
        select * from work
        order by customorder
        """
      );
    }else{ //선택되어 있을 때
      queryResult = await db.rawQuery(
        """
        select * from work
        where category_seq = ?
        order by customorder
        """,
        [cat]
      );
    }
    return queryResult.map((e) => Work.fromMap(e)).toList();
  }

  //작업 순서 바꾸기
  Future<void> updateWorkOrder(List<Work> list) async {
    final Database db = await initializeDB();
    for (int i = 0; i < list.length; i++) {
      await db.rawUpdate(
        '''
        update work
        set customorder = ?
        where seq = ?
        ''',
        [i, list[i].seq],
      );
    }
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
        (category_seq, checkdate, content, duedate, duetime, repeat, memo, image, customorder, mark, initdate)
        values
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, date('now'))
      """,
      [
        work.category_seq,
        work.checkdate,
        work.content,
        work.duedate,
        work.duetime,
        work.repeat,
        work.memo,
        work.image,
        nextOrder,
        work.mark,
      ]
    );
    return result;
  }

  //작업 수정
  Future<int> updateWork(Work work) async{
    final Database db = await initializeDB();
    int result = 0;
    result = await db.rawUpdate(
      """
      update work
      set category_seq = ?, content = ?, duedate = ?, duetime = ?, repeat = ?, memo = ?, image = ?
      where seq = ?
      """,
      [work.category_seq, work.content, work.duedate, work.duetime, work.repeat, work.memo, work.image, work.seq]
    );
    return result;
  }

  //작업 체크
  Future<void> workCheck(int seq, bool isChecked) async{
    final Database db = await initializeDB();
    if (isChecked){
      await db.rawUpdate(
        """
        update work
        set checkdate = date('now')
        where seq = ?
        """,
        [seq]
      );
    }else{
      await db.rawUpdate(
        """
        update work
        set checkdate = null
        where seq = ?
        """,
        [seq]
      );
    }
  }  

  //위치 추가
  Future<int> addPlace(Place place) async{
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      """
        insert into place
        (work_seq, lat, lng, name)
        values
        (?, ?, ?, ?)
      """,
      [place.work_seq, place.lat, place.lng, place.name]
    );
    return result;
  }

  //위치 가져오기
  Future<List<Place>> listPlace(int work_seq) async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      """
      select * from place
      where work_seq = ?
      """,
      [work_seq]
    );
    return queryResult.map((e) => Place.fromMap(e)).toList();
  }

  //위치 수정
  Future<int> updatePlace(Place place) async{
    final Database db = await initializeDB();
    int result = 0;
    result = await db.rawUpdate(
      """
      update place
      set lat = ?, lng = ?, name = ?
      where seq = ?
      """,
      [place.lat, place.lng, place.name, place.seq]
    );
    return result;
  }  

  //위치 삭제
  Future<void> deletePlace(int seq) async{
    final Database db = await initializeDB();
    await db.rawUpdate(
    """
      delete from place
      where seq = ?
    """,
    [seq]
    );
  }  

  //하위 항목 추가
  Future<int> addDetail(List<Detail> detailList) async{
    int result = 0;
    final Database db = await initializeDB();
    for(Detail detail in detailList){
      //다음 customorder값 확인
      var maxOrderResult = await db.rawQuery(
        "select ifnull(max(customorder), 0) + 1 as next from detail where work_seq = ?",
        [detail.work_seq]
      );
      var nextOrder = maxOrderResult.first['next'];
      result = await db.rawInsert(
        """
          insert into detail
          (work_seq, checked, content, customorder)
          values
          (?, 0, ?, ?)
        """,
        [detail.work_seq, detail.content, nextOrder]
      );
      if(result == 0) return 0;
    }
    return result;
  }

  //하위 항목 리스트
  Future<List<Detail>> listDetail(int work_seq) async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      """
      select * from detail
      where work_seq = ?
      order by customorder
      """,
      [work_seq]
    );
    return queryResult.map((e) => Detail.fromMap(e)).toList();
  }

  //하위항목 삭제
  Future<void> deleteDetail(List<int> list) async{
    final Database db = await initializeDB();
    for(int data in list){
      final List<Map<String, Object?>> queryResult = await db.rawQuery(//customorder값 찾기
        """
        select customorder
        from detail
        where seq = ?
        """,
        [data]
      );
      await db.rawUpdate(//삭제
      """
        delete from detail
        where seq = ?
      """,
      [data]
      );
      int order = queryResult.first['customorder'] as int;
      await db.rawUpdate( //나머지 하위항목의 순서 당기기
        '''
        update detail
        set customorder = customorder - 1
        where customorder > ?
        ''',
        [order]
      );
    }    
  }   

}