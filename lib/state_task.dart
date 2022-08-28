import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_task.dart';
import 'api_notification.dart';

class MyStateTask extends ChangeNotifier {
  List<MyTasksModel> tasks = [];
  List<MyTasksModel> tasksPending = [];
  List<MyTasksModel> tasksForLater = [];
  List<MyTasksModel> tasksFinished = [];
  List<MyTasksModel> tasksDeleted = [];
  int count = 0;
  late MyTasksDB db;

  MyStateTask() {
    load();
  }

  Future<void> loadTasksPending() async {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasksPending = await db.listTasksPending();
      notifyListeners();
    });
  }

  Future<void> loadTasksForLater() async {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasksForLater = await db.listTasksForLater();
      notifyListeners();
    });
  }

  Future<void> loadTasksFinished() async {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasksFinished = await db.listTasksFinished();
      notifyListeners();
    });
  }

  Future<void> loadTasksDeleted() async {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      tasksDeleted = await db.listTasksDeleted();
      notifyListeners();
    });
  }

  Future<void> load() async {
    await loadTasksPending();
    await loadTasksForLater();
    await loadTasksFinished();
    await loadTasksDeleted();
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

  void reorderList(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    notifyListeners();
  }

  Future<String?> updateScheduleDateTime(
      MyTasksModel task, DateTime? date, TimeOfDay? time) async {
    db = MyTasksDB();
    var result = 'Erro, tente novamente';
    db.init().whenComplete(() async {
      result = await db.updateScheduleDateTime(task.id, date, time);
    });

    const notification = ApiNotification();
    await notification.showNotificationWithCustomTimestamp(task, date, time);

    await load();

    return result;
  }

  Future<void> updateFinishedAt(int id) async {
    db = MyTasksDB();
    db.init().whenComplete(() async {
      await db.updateFinishedAt(id);
    });
  }
}

class MyNavi2Task {
  final MyTasksModel task;
  MyNavi2Task(this.task);
}
