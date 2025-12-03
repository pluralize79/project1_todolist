import 'package:flutter/foundation.dart';
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
            check integer,
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
            themecolor integer
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

  //Add 
  Future<int> addWork(Work work) async{
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      """
        insert into work
        (category_seq, place_seq, checkdate, content, duedate, duetime, memo, image)
        values
        (?, ?, ?, ?, ?, ?, ?, ?)
      """,
      [
        work.category_seq,
        work.place_seq,
        work.checkdate,
        work.content,
        work.duedate,
        work.duetime,
        work.memo,
        work.image
      ]
    );
    return result;
  }
  
  Future<int> addCategorys(Categorys categorys) async{
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      """
        insert into categorys
        (title, customorder)
        values
        (?, select ifnull(max(customorder), 0) + 1 from category)
      """,
      [categorys.title]
    );
    return result;
  }


}