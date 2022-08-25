import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_task.dart';
import 'api_notification.dart';

class MyStateTask extends ChangeNotifier {
  List<MyTasksModel> tasks = [];
  int count = 0;
  late MyTasksDB db;

  MyStateTask() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    count = (prefs.getInt('MyTodoList_count') ?? 0);

    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasks = await db.list();
      notifyListeners();
    });
  }

  void create(String title) async {
    final prefs = await SharedPreferences.getInstance();
    var task = MyTasksModel(
        id: count,
        title: title,
        description: '---',
        active: 1,
        scheduleAt: DateTime.now().toString());

    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.insertTask(task);
    });
    count++;
    tasks.insert(0, task);
    prefs.setInt('MyTodoList_count', count);
    notifyListeners();
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
        active: 1,
        scheduleAt: DateTime.now().toString());

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

  void changeActive(int id) {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.changeActive(id);
      load();
      notifyListeners();
    });
  }

  Future<String?> updateScheduleDateTime(
      int id, int index, DateTime? date, TimeOfDay? time) async {
    db = MyTasksDB();
    var result = 'Erro, tente novamente';
    db.init().whenComplete(() async {
      result = await db.updateScheduleDateTime(id, date, time);
    });

    await load();

    const notification = ApiNotification();
    await notification.showNotificationWithCustomTimestamp(
        tasks[index], date, time);

    return result;
  }
}

class MyNavi2Task {
  final int index;
  final int id;
  final String title;

  MyNavi2Task(this.id, this.title, this.index);
}
