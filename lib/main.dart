import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_task.dart';
import 'state_task.dart';

void main() {
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
        primarySwatch: Colors.blue,
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
  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
        builder: (context, value, child) => Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: value.tasks.isEmpty
                  ? const Center(
                      child: Text('Vazio'),
                    )
                  : ListView.builder(
                      itemCount: value.tasks.length,
                      itemBuilder: (BuildContext context, index) => MyTask(
                        id: value.tasks[index].id,
                        title: value.tasks[index].title,
                        description: value.tasks[index].description,
                        active: value.tasks[index].active,
                        index: index,
                      ),
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: value.increment,
                child: const Icon(Icons.add),
              ),
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
          value.delete(widget.id);
        },
        child: Container(
          height: 80,
          color: widget.active == 0 ? Colors.yellow[100] : Colors.green[300],
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 35),
                ),
                Text(widget.description),
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
        appBar: AppBar(title: Text(args.title)),
        body: MyTaskForm(index: args.index),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MyStateTask>(
      builder: (context, value, child) => Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: value.tasks[widget.index].title,
              validator: (title) {},
              onSaved: (String? title) {
                print(title);
                if (title != null) {
                  MyTasksModel task = MyTasksModel(
                      id: value.tasks[widget.index].id,
                      title: title,
                      description: '---',
                      active: 1);
                  int id = value.tasks[widget.index].id;
                  value.update(id, task);
                }
              },
            ),
            ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                  }
                },
                child: const Text('Alterar'))
          ],
        ),
      ),
    );
  }
}
