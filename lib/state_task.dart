import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_task.dart';

class MyStateTask extends ChangeNotifier {
  List<MyTasksModel> tasks = [];
  int count = 0;
  late MyTasksDB db;

  MyStateTask() {
    load();
  }

  void load() async {
    final prefs = await SharedPreferences.getInstance();

    count = (prefs.getInt('MyTodoList_count') ?? 0);

    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasks = await db.list();
      notifyListeners();
    });
  }

  int tasksLenght() {
    return tasks.length;
  }

  void increment() async {
    final prefs = await SharedPreferences.getInstance();

    var task = MyTasksModel(
        id: count,
        title: 'title ${count}',
        description: 'description ${count}',
        active: 1);

    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.insertTask(task);
    });
    count++;
    tasks.insert(0, task);

    prefs.setInt('MyTodoList_count', count);
    notifyListeners();
  }

  void delete(int id) {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.delete(id);
      load();
      notifyListeners();
    });
  }

  void update(int id, MyTasksModel task) {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.update(task, id);
      load();
      notifyListeners();
    });
  }
}

class MyNavi2Task {
  final int index;
  final int id;
  final String title;

  MyNavi2Task(this.id, this.title, this.index);
}