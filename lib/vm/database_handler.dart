import 'package:path/path.dart';
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
          create table category
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
}