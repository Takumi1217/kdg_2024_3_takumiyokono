import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodosNotifierProvider(
        notifier: TodosNotifier(),
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Offset _mousePosition;

  void _addTodo() {
    TodosNotifierProvider.of(context).addTodo(_mousePosition);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = TodosNotifierProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.amber[50],
      body: GestureDetector(
        // TapDown時に位置取得し、Tap時（指を離した）に_addTodoを実行
        onDoubleTapDown: (details) => _mousePosition = details.localPosition,
        onDoubleTap: _addTodo,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // カラーを指定しないと上のGestureDetectorの範囲がchildの範囲に収まってしまう
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              for (final todo in notifier.value)
                Positioned(
                  left: todo.position.dx,
                  top: todo.position.dy,
                  child: GestureDetector(
                    // downにすることで移動開始が少し早まる
                    dragStartBehavior: DragStartBehavior.down,
                    onPanUpdate: (details) {
                      notifier.move(details.delta, todo.id);
                    },
                    child: TodoWidgetWithButtons(
                      todo: todo,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodoWidgetWithButtons extends StatefulWidget {
  final TodoModel todo;

  const TodoWidgetWithButtons({Key? key, required this.todo}) : super(key: key);

  @override
  _TodoWidgetWithButtonsState createState() => _TodoWidgetWithButtonsState();
}

class _TodoWidgetWithButtonsState extends State<TodoWidgetWithButtons>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 800);

  // forward().then()のsetStateはAnimationControllerのisCompletedパラメーターをWidgetに読み込むため
  // lateで宣言しつつ代入すると、initState内で代入するのと同じ効果がある
  late final _animationController = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward().then((value) => setState(() {}));

  late final _textController = TextEditingController();

  bool _editMode = false;

  void _changeDescription() {
    // テキスト内容が変わっている時のみ実行
    if (_textController.text != widget.todo.description) {
      TodosNotifierProvider.of(context)
          .changeDescription(_textController.text, widget.todo.id);
    }
    setState(() => _editMode = false);
  }

  void _toggleEditMode() {
    if (_editMode) {
      _changeDescription();
    } else {
      setState(() => _editMode = true);
    }
  }

  void _toggleDone() {
    TodosNotifierProvider.of(context).toggleDone(widget.todo.id);
  }

  void _toggleSex() {
    TodosNotifierProvider.of(context).toggleSex(widget.todo.id);
  }

  void _delete() {
    // then()の後にdeleteしないと即時削除されてアニメーションが見れない
    _animationController.reverse().then((value) {
      TodosNotifierProvider.of(context).delete(widget.todo.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Explicit Animation
    return ScaleTransition(
      // アニメーションの状態によりCurveを変化
      scale: _animationController.drive(
        CurveTween(
          curve: _animationController.isCompleted
              ? Curves.bounceIn
              : Curves.bounceOut,
        ),
      ),
      child: SizedBox(
        width: TodoWidget.imageSize.width,
        height: TodoWidget.imageSize.height,
        child: Stack(
          children: [
            // Todoメモの本体
            _buildAnimatedTodo(),
            // 周りのボタン類
            _buildEditButton(),
            _buildSexButton(),
            _buildDeleteButton(),
            _buildCheckButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTodo() {
    // Implicit Animation
    return AnimatedOpacity(
      opacity: widget.todo.done ? 0.25 : 1.0,
      curve: Curves.easeOutQuint,
      duration: _duration,
      child: TodoWidget(
        controller: _textController,
        todo: widget.todo,
        editMode: _editMode,
        onSubmitted: _changeDescription,
        onEditMode: _toggleEditMode,
      ),
    );
  }

  Widget _buildCheckButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        iconSize: 45,
        icon: Icon(
          widget.todo.done ? Icons.check_circle : Icons.circle_outlined,
        ),
        color: Colors.amber,
        onPressed: _toggleDone,
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      left: 10,
      bottom: 60,
      child: IconButton(
        icon: const Icon(Icons.delete_rounded),
        color: Colors.black45,
        onPressed: _delete,
      ),
    );
  }

  Widget _buildSexButton() {
    return Positioned(
      left: 10,
      top: 10,
      child: IconButton(
        iconSize: 45,
        icon: Icon(
          widget.todo.sex == Sex.girl ? Icons.swap_horiz : Icons.swap_horiz,
        ),
        color: (widget.todo.sex == Sex.boy ? Colors.red : Colors.blue)
            .withOpacity(0.50),
        onPressed: _toggleSex,
      ),
    );
  }

  Widget _buildEditButton() {
    return Positioned(
      right: 15,
      top: 15,
      child: IconButton(
        icon: Icon(_editMode ? Icons.done_rounded : Icons.edit),
        color: Colors.black45,
        onPressed: _toggleEditMode,
      ),
    );
  }
}

class TodoWidget extends StatefulWidget {
  final TextEditingController controller;
  final TodoModel todo;
  final bool editMode;
  final VoidCallback? onSubmitted;
  final VoidCallback? onEditMode;

  const TodoWidget({
    Key? key,
    required this.controller,
    required this.todo,
    required this.editMode,
    required this.onEditMode,
    this.onSubmitted,
  }) : super(key: key);

  static const image = <Sex, String>{
    Sex.boy:
        'https://frame-illust.com/fi/wp-content/uploads/2015/01/795301709d0f81ce3e13dcb60003da05.png',
    Sex.girl:
        'https://frame-illust.com/fi/wp-content/uploads/2015/01/c875da7203d46d70757aa17c831dc7f2.png',
  };

  static const imageSize = Size(260, 280);

  @override
  _TodoWidgetState createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.todo.description;
  }

  @override
  Widget build(BuildContext context) {
    // 編集モード時にTextField以外をタップすると編集モードが解除
    return GestureDetector(
      onTap: widget.editMode ? widget.onSubmitted?.call : null,
      child: Container(
        width: TodoWidget.imageSize.width,
        height: TodoWidget.imageSize.height,
        padding: const EdgeInsets.fromLTRB(40, 65, 40, 85),
        decoration: BoxDecoration(
          image: DecorationImage(
            alignment: Alignment.topLeft,
            fit: BoxFit.fitWidth,
            image: NetworkImage(TodoWidget.image[widget.todo.sex]!),
          ),
        ),
        // 編集モード時はTextField、それ以外はテキスト表示
        // テキストをダブルクリックすると編集モードになる
        child: !widget.editMode
            ? GestureDetector(
                onDoubleTap: widget.onEditMode,
                child: Text(
                  widget.todo.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              )
            : TextField(
                controller: widget.controller,
                maxLines: null,
                maxLength: 100,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'メモ',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
      ),
    );
  }
}

enum Sex { girl, boy }

@immutable
class TodoModel {
  final Key id;
  final Offset position;
  final String description;
  final Sex sex;
  final bool done;

  const TodoModel({
    required this.id,
    required this.position,
    this.description = '',
    this.sex = Sex.girl,
    this.done = false,
  });

  TodoModel copyWith({
    Key? id,
    Offset? position,
    String? description,
    Sex? sex,
    bool? done,
  }) {
    return TodoModel(
      id: id ?? this.id,
      position: position ?? this.position,
      description: description ?? this.description,
      sex: sex ?? this.sex,
      done: done ?? this.done,
    );
  }
}

class TodosNotifier extends ValueNotifier<List<TodoModel>> {
  TodosNotifier() : super(<TodoModel>[]) {
    _init();
  }

  void _init() {
    // Todoリストの初期値
    super.value = [
      TodoModel(
        id: UniqueKey(),
        position: const Offset(20, 60),
        description: '新規メモ',
        sex: Sex.boy,
      ),
      TodoModel(
        id: UniqueKey(),
        position: const Offset(120, 350),
        description: '新規メモ',
        sex: Sex.girl,
      ),
    ];
  }

  void addTodo(Offset position) {
    final todo = TodoModel(
      id: UniqueKey(),
      // positionは左上隅のOffsetなので画像の大きさの半分を縦横それぞれ引くことで中央寄せ
      position: position -
          Offset(
            TodoWidget.imageSize.width / 2,
            TodoWidget.imageSize.height / 2,
          ),
      description: '新規メモ',
    );
    super.value.add(todo);
    // super.valueのリスト自体を入れ替えない場合はnotifyListeners()が必要
    notifyListeners();
  }

  void move(Offset delta, Key? id) {
    final list = value.map<TodoModel>((e) {
      if (e.id == id) {
        return e.copyWith(position: e.position + delta);
      }
      return e;
    }).toList();
    super.value = list;
  }

  void changeDescription(String description, Key? id) {
    final list = value.map<TodoModel>((e) {
      if (e.id == id) {
        return e.copyWith(description: description);
      }
      return e;
    }).toList();
    super.value = list;
  }

  void toggleDone(Key? id) {
    final list = value.map<TodoModel>((e) {
      if (e.id == id) {
        return e.copyWith(done: !e.done);
      }
      return e;
    }).toList();
    super.value = list;
  }

  void toggleSex(Key? id) {
    final list = value.map<TodoModel>((e) {
      if (e.id == id) {
        return e.copyWith(sex: e.sex == Sex.boy ? Sex.girl : Sex.boy);
      }
      return e;
    }).toList();
    super.value = list;
  }

  void delete(Key? id) {
    super.value.removeWhere((element) => element.id == id);
    notifyListeners();
  }
}

class TodosNotifierProvider extends InheritedNotifier {
  const TodosNotifierProvider({
    required TodosNotifier notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static TodosNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TodosNotifierProvider>()!
        .notifier as TodosNotifier;
  }
}
