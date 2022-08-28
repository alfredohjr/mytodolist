import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MyTasksDB {
  Future<Database> init() async {
    String path = await getDatabasesPath();
    return openDatabase(join(path, 'MyTodoListV6.db'),
        onCreate: (db, version) async {
      await db.execute(_createTable000Lists);
      await db.rawInsert(_createTable000ListsDefaultRow);
      await db.execute(_createTable001Tasks);
    }, version: 1);
  }

  String _createTable000Lists = '''
        create table lists(id INTEGER PRIMARY KEY
                            , name TEXT
                            , description TEXT 
                            , createdAt datetime default current_timestamp
                            , updatedAt datetime default current_timestamp
                            , active BOOLEAN DEFAULT 1
                            , deletedAt DATETIME
                            , periodType VARCHAR(3) default 'D'
                            , periodNumber INTEGER default 1
        )''';

  String _createTable000ListsDefaultRow = ''' 
        INSERT INTO lists(name,description) VALUES('TodoList','Lista padrão')''';

  String _createTable001Tasks = '''
        create table tasks(id INTEGER PRIMARY KEY
                              , title TEXT
                              , description TEXT
                              , list REFERENCES lists(id)
                              , active BOOLEAN
                              , priority INTEGER
                              , tags TEXT
                              , scheduleAt datetime default current_timestamp
                              , finishedAt datetime
                              , deletedAt datetime  
                              , createdAt datetime default current_timestamp
                              , updateAt datetime default current_timestamp)
''';

  void insertList() {}
  void listList() {}
  void deleteList() {}
  void updateList() {}
  void changeActiveList() {}
  void updatePriority() {}

  Future<List<MyTasksModel>> listTasksMain(String where) async {
    final Database db = await init();
    final List<Map<String, dynamic>> maps =
        await db.query('tasks', where: where, orderBy: 'priority');

    return List.generate(maps.length, (i) {
      return MyTasksModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        active: maps[i]['active'],
        scheduleAt: maps[i]['scheduleAt'],
      );
    });
  }

  Future<List<MyTasksModel>> listTasksPending() async {
    return await listTasksMain(
        "finishedAt is null and deletedAt is null and scheduleAt <= datetime('now')");
  }

  Future<List<MyTasksModel>> listTasksForLater() async {
    return await listTasksMain("scheduleAt > datetime('now')");
  }

  Future<List<MyTasksModel>> listTasksFinished() async {
    return await listTasksMain("finishedAt is not null or finishedAt = ''");
  }

  Future<List<MyTasksModel>> listTasksDeleted() async {
    return await listTasksMain("deletedAt is not null");
  }

  Future<int> insertTask(MyTasksModel task) async {
    final Database db = await init();
    await db.insert('tasks', task.toMap());
    return 0;
  }

  Future<List<MyTasksModel>> list() async {
    final Database db = await init();
    final List<Map<String, dynamic>> maps =
        await db.query('tasks', orderBy: '-id');

    return List.generate(maps.length, (i) {
      return MyTasksModel(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        active: maps[i]['active'],
        scheduleAt: maps[i]['scheduleAt'],
      );
    });
  }

  Future<int> delete(int id) async {
    final Database db = await init();
    await db.rawUpdate(
        "UPDATE tasks SET deletedAt = datetime('now') where id = ? ", [id]);
    print('oi ${id}');
    return 0;
  }

  Future<int> update(MyTasksModel task, int id) async {
    final Database db = await init();
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [id]);
    return 0;
  }

  Future<int> changeActive(int id) async {
    final Database db = await init();
    int active = 0;

    var result =
        await db.rawQuery('select active from tasks where id = ?', [id]);

    if (result.isNotEmpty) {
      if (result[0]['active'] == 1) {
        active = 0;
      } else {
        active = 1;
      }
    }

    await db
        .rawUpdate('update tasks set active = ? where id = ?', [active, id]);
    return 0;
  }

  Future<int> updateFinishedAt(int id) async {
    final Database db = await init();
    String finishedAt = '';

    var result =
        await db.rawQuery('select finishedAt from tasks where id = ?', [id]);

    if (result.isNotEmpty) {
      if (result[0]['finishedAt'] == null) {
        finishedAt = DateTime.now().toString();
      }
    }

    await db.rawUpdate(
        'update tasks set finishedAt = ? where id = ?', [finishedAt, id]);
    return 0;
  }

  Future<String> updateScheduleDateTime(
      int id, DateTime? date, TimeOfDay? time) async {
    if (date != null) {
      String dateFormatted =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      String datePTBRFormatted =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

      String timeFormatted = '00:00';
      if (time != null) {
        timeFormatted =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      String finalDateTimeFormatted = '${dateFormatted} ${timeFormatted}:00';

      final Database db = await init();
      await db.rawUpdate('update tasks set scheduleAt = ? where id = ?',
          [finalDateTimeFormatted, id]);

      return '${datePTBRFormatted} ${timeFormatted}';
    } else {
      return 'Informe uma data';
    }
  }
}

class MyTasksModel {
  final int id;
  final String title;
  final String description;
  final int active;
  final String scheduleAt;

  MyTasksModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.active,
      required this.scheduleAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'active': 1,
      'scheduleAt': scheduleAt
    };
  }
}
