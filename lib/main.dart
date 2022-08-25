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
              floatingActionButton: FloatingActionButton(onPressed: () async {
                await _showNotificationWithCustomTimestamp();
              }),
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
        builder: (context, value, child) => value.tasks.isEmpty
            ? const Center(
                child: Text('Vazio', style: TextStyle(color: Colors.white)),
              )
            : SingleChildScrollView(
                child: Column(children: <Widget>[
                  ExpansionTile(
                      title: Text('Pendentes'),
                      initiallyExpanded: true,
                      collapsedTextColor: Colors.white,
                      collapsedIconColor: Colors.white,
                      children: <Widget>[
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(
                            50,
                            0,
                            50,
                            0,
                          ),
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(height: 3),
                          itemCount: value.tasks.length,
                          itemBuilder: (BuildContext context, index) => MyTask(
                            id: value.tasks[index].id,
                            title: value.tasks[index].title,
                            description: value.tasks[index].description,
                            active: value.tasks[index].active,
                            index: index,
                          ),
                        )
                      ]),
                  ExpansionTile(
                    title: Text('Adiados'),
                    collapsedTextColor: Colors.white,
                    collapsedIconColor: Colors.white,
                  ),
                  ExpansionTile(
                    title: Text('Finalizados'),
                    collapsedTextColor: Colors.white,
                    collapsedIconColor: Colors.white,
                  ),
                  ExpansionTile(
                    title: Text('Excluídos'),
                    collapsedTextColor: Colors.white,
                    collapsedIconColor: Colors.white,
                  ),
                ]),
              ));
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
              arguments: MyNavi2Task(widget.id, widget.title, widget.index));
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
          title: Text(args.title),
          backgroundColor: const Color.fromRGBO(58, 80, 107, 1),
        ),
        body: MyTaskForm(index: args.index),
        backgroundColor: const Color.fromRGBO(28, 37, 65, 1),
      ),
    );
  }
}

class MyTaskForm extends StatefulWidget {
  MyTaskForm({super.key, required this.index});

  final index;

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
                  initialValue: value.tasks[widget.index].title,
                  style: TextStyle(color: Colors.white),
                  decoration: inputDecoration('Titulo'),
                  validator: (title) {},
                  onSaved: (title) {
                    if (title != null) {
                      MyTasksModel task = MyTasksModel(
                          id: value.tasks[widget.index].id,
                          title: title,
                          description: '---',
                          active: 1,
                          scheduleAt: DateTime.now().toString());
                      int id = value.tasks[widget.index].id;
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
                    initialValue: value.tasks[widget.index].description),
                SizedBox(height: 15),
                TextField(
                  decoration: inputDecoration('Adiar até'),
                  controller: TextEditingController(
                      text: value.tasks[widget.index].scheduleAt.toString()),
                  style: TextStyle(color: Colors.white),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030));

                    TimeOfDay? time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());

                    String? datePTBRFormatted =
                        await value.updateScheduleDateTime(
                            value.tasks[widget.index].id,
                            widget.index,
                            date,
                            time);
                    if (datePTBRFormatted != null) {
                      datetimeController.text = datePTBRFormatted;
                    }
                  },
                ),
                SizedBox(height: 15),
                TextField(decoration: inputDecoration('tags')),
                SizedBox(height: 15),
                Checkbox(
                    value: value.tasks[widget.index].active == 0 ? false : true,
                    side: BorderSide(color: Colors.white, width: .2),
                    onChanged: (nv) {
                      value.changeActive(value.tasks[widget.index].id);
                    }),
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
