import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'model_task.dart';
import 'state_task.dart';
import 'api_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {});

  runApp(ChangeNotifierProvider(
    create: (context) => MyStateTask(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My TodoList',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(28, 37, 65, 1),
      ),
      home: const MyHomePage(title: 'TodoList'),
      routes: <String, WidgetBuilder>{
        '/task': (BuildContext context) => MyTaskDetail(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _showNotificationWithCustomTimestamp() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '1111',
      'NumeroUmname',
      channelDescription: 'NumeroUmdescription',
      importance: Importance.max,
      priority: Priority.high,
      when: DateTime.now().millisecondsSinceEpoch + 5000,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        10,
        'plain title',
        'plain body',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
        builder: (context, value, child) => Scaffold(
              appBar: AppBar(
                title: Text('TodoList'),
                actions: [
                  Icon(
                    Icons.construction,
                    color: Colors.white,
                  ),
                ],
                backgroundColor: const Color.fromRGBO(58, 80, 107, 1),
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _MyAddTask(),
                  Expanded(child: _MyListTasks())
                ],
              ),
              backgroundColor: const Color.fromRGBO(28, 37, 65, 1),
            ));
  }
}

class _MyAddTask extends StatelessWidget {
  _MyAddTask({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();
  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(50, 5, 90, 20),
      child: Consumer<MyStateTask>(
        builder: (context, value, child) => TextField(
          style: TextStyle(color: Colors.white),
          controller: controller,
          onSubmitted: (title) {
            if (title.length > 5) {
              value.create(title);
              controller.text = '';
            }
          },
          decoration: const InputDecoration(
            icon: Icon(Icons.add, color: Colors.white),
            labelText: 'Tarefa',
            labelStyle: TextStyle(color: Colors.white),
            border: UnderlineInputBorder(),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: .2)),
          ),
        ),
      ),
    );
  }
}

class _MyListTasks extends StatelessWidget {
  _MyListTasks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
        builder: (context, value, child) => SingleChildScrollView(
              child: Column(children: <Widget>[
                MyExpansionList(title: 'Pendentes', tasks: value.tasksPending),
                MyExpansionList(title: 'Adiados', tasks: value.tasksForLater),
                MyExpansionList(
                    title: 'Finalizados', tasks: value.tasksFinished),
                MyExpansionList(title: 'Excluidos', tasks: value.tasksDeleted),
              ]),
            ));
  }
}

class MyExpansionList extends StatelessWidget {
  final String title;
  final List<MyTasksModel> tasks;
  MyExpansionList({Key? key, required this.title, required this.tasks})
      : super(key: key);

  @override
  Widget build(BuildContext build) {
    return Consumer<MyStateTask>(
      builder: (context, value, child) => ExpansionTile(
          title: Text(title),
          trailing: Text('${tasks.length}'),
          initiallyExpanded: true,
          collapsedTextColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: <Widget>[
            ReorderableListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: 30),
                onReorder: (oldIndex, newIndex) =>
                    {value.reorderList(oldIndex, newIndex)},
                children: <Widget>[
                  for (final item in tasks)
                    ListTile(
                      key: ValueKey(item),
                      title: Text(item.title),
                      subtitle: Text(item.description),
                      textColor: Colors.white,
                      selectedColor: Colors.black,
                      onTap: () {
                        Navigator.pushNamed(context, '/task',
                            arguments: MyNavi2Task(item));
                      },
                      onLongPress: () {},
                      hoverColor: Colors.black12,
                    )
                ]),
          ]),
    );
  }
}

class MyTask extends StatefulWidget {
  MyTask(
      {Key? key,
      required this.title,
      required this.description,
      required this.active,
      required this.id,
      required this.index})
      : super(key: key);
  final String title;
  final String description;
  final int active;
  final int id;
  final int index;

  @override
  State<MyTask> createState() => _MyTask();
}

class _MyTask extends State<MyTask> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
      builder: (context, value, child) => GestureDetector(
        onDoubleTap: () {
          Navigator.pushNamed(context, '/task',
              arguments: MyNavi2Task(value.tasks[0]));
        },
        onTap: () {
          value.changeActive(widget.id);
        },
        onLongPress: () {
          value.delete(widget.id);
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.active == 1
                ? Color.fromRGBO(91, 192, 190, 1)
                : Colors.green[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyTaskDetail extends StatelessWidget {
  MyTaskDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MyNavi2Task;

    return Consumer<MyStateTask>(
      builder: (context, value, child) => Scaffold(
        appBar: AppBar(
          title: Text(args.task.title),
          backgroundColor: const Color.fromRGBO(58, 80, 107, 1),
        ),
        body: MyTaskForm(task: args.task),
        backgroundColor: const Color.fromRGBO(28, 37, 65, 1),
      ),
    );
  }
}

class MyTaskForm extends StatefulWidget {
  MyTaskForm({super.key, required this.task});

  MyTasksModel task;

  @override
  MyTaskFormState createState() {
    return MyTaskFormState();
  }
}

class MyTaskFormState extends State<MyTaskForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController datetimeController = TextEditingController();

  InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.white),
      suffixStyle: TextStyle(color: Colors.white),
      border: UnderlineInputBorder(),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: .2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
      builder: (context, value, child) => Container(
        padding: EdgeInsets.fromLTRB(50, 20, 50, 30),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: widget.task.title,
                  style: TextStyle(color: Colors.white),
                  decoration: inputDecoration('Titulo'),
                  validator: (title) {},
                  onSaved: (title) {
                    if (title != null) {
                      MyTasksModel task = MyTasksModel(
                          id: widget.task.id,
                          title: title,
                          description: widget.task.description,
                          active: widget.task.active,
                          scheduleAt: DateTime.now().toString());
                      int id = widget.task.id;
                      value.update(id, task);
                    }
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                    decoration: inputDecoration('Descrição'),
                    minLines: 5,
                    maxLines: 8,
                    style: TextStyle(color: Colors.white),
                    initialValue: widget.task.description),
                SizedBox(height: 15),
                TextField(
                  decoration: inputDecoration('Adiar até'),
                  controller: TextEditingController(
                      text: widget.task.scheduleAt.toString()),
                  style: TextStyle(color: Colors.white),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030));

                    TimeOfDay? time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());

                    String? datePTBRFormatted = await value
                        .updateScheduleDateTime(widget.task, date, time);
                    if (datePTBRFormatted != null) {
                      datetimeController.text = datePTBRFormatted;
                    }
                  },
                ),
                SizedBox(height: 15),
                TextField(decoration: inputDecoration('tags')),
                SizedBox(height: 15),
                DropdownButton(
                  hint: Text(
                    'Trocar de lista',
                    style: TextStyle(color: Colors.white),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      child: Text('Default'),
                      value: "default",
                    )
                  ],
                  onChanged: (newValue) => {},
                ),
                SizedBox(height: 15),
                SwitchListTile(
                    title: Text(
                      'Finalizado',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: false,
                    onChanged: (bool newValue) => {}),
                SwitchListTile(
                    title: Text(
                      'Ativo',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Para você saber o que está executando',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: true,
                    onChanged: (bool newValue) => {}),
                SwitchListTile(
                    title: Text(
                      'Deletar',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Marca a tarefa como deletada, mas ainda pode ser recuperada',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: true,
                    onChanged: (bool newValue) => {}),
                SwitchListTile(
                    title: Text(
                      'Deletar em definitivo',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Excluí a tarefa',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: true,
                    onChanged: (bool newValue) => {})
              ],
            ),
          ),
        ),
      ),
    );
  }
}
