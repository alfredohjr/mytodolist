import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MyTasksDB {
  Future<Database> init() async {
    String path = await getDatabasesPath();
    return openDatabase(join(path, 'MyTodoList.db'), onCreate: (db, version) {
      return db.execute(
          'create table tasks(id INTEGER PRIMARY KEY, title TEXT, description TEXT, active BOOLEAN)');
    }, version: 1);
  }

  Future<int> insertTask(MyTasksModel task) async {
    final Database db = await init();
    await db.insert('tasks', task.toMap());
    print('ola');
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
      );
    });
  }

  Future<int> delete(int id) async {
    final Database db = await init();
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
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
}

class MyTasksModel {
  final int id;
  final String title;
  final String description;
  final int active;

  MyTasksModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.active});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'active': 1,
    };
  }
}
