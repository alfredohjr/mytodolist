import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              body: ListView.builder(
                itemCount: value.tasks.length,
                itemBuilder: (BuildContext context, index) => MyTask(
                  id: value.tasks[index].id,
                  title: value.tasks[index].title,
                  description: value.tasks[index].description,
                  active: value.tasks[index].active,
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
      required this.id})
      : super(key: key);
  final String title;
  final String description;
  final bool active;
  final int id;

  @override
  State<MyTask> createState() => _MyTask();
}

class _MyTask extends State<MyTask> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('<${widget.title}>');
        Navigator.pushNamed(context, '/task',
            arguments: MyNavi2Task(widget.id, widget.title));
      },
      child: Container(
        height: 80,
        color: widget.active ? Colors.yellow[100] : Colors.green[300],
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
        body: MyTaskForm(id: args.id),
      ),
    );
  }
}

class MyTaskForm extends StatefulWidget {
  MyTaskForm({super.key, required this.id});

  final id;

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
              initialValue: value.tasks[widget.id].title,
              validator: (title) {},
              onSaved: (String? title) {
                print(title);
                value.update(widget.id, title);
              },
            ),
            ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    print('legal!');
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

class MyTasksModel {
  int id;
  String title;
  String description;
  bool active;

  MyTasksModel(this.id, this.title, this.description, this.active);
}

class MyStateTask extends ChangeNotifier {
  final List<MyTasksModel> tasks = [
    MyTasksModel(0, 'a', 'b', true),
    MyTasksModel(1, 'a1', 'b5', true),
    MyTasksModel(2, 'a2', 'b6', false),
    MyTasksModel(3, 'a3', 'b7', true),
    MyTasksModel(4, 'a4', 'b8', false),
  ];
  int count = 5;

  void increment() {
    tasks.add(MyTasksModel(count, 'a $count', 'b ${count * 10}', false));
    count++;
    notifyListeners();
  }

  void update(int id, String? title) {
    tasks[id].title = title == null ? "NA" : title;
    notifyListeners();
  }
}

class MyNavi2Task {
  final int id;
  final String title;

  MyNavi2Task(this.id, this.title);
}
