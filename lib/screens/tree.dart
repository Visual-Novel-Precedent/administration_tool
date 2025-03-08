import 'package:flutter/material.dart';

import '../backend_clients/node/get_node_by_id.dart';
import '../backend_clients/node/get_nodes_by_chapter_id.dart';
import '../models/node.dart';
import 'package:collection/collection.dart';

// Класс для представления узла дерева
class Node {
  BigInt id;
  String title;
  List<Node> children;

  Node({
    required this.id,
    required this.title,
    List<Node>? children,
  }) : children = children ?? [];

  factory Node.empty(BigInt id, String title) {
    return Node(id: id, title: title, children: []);
  }

  @override
  String toString() {
    return 'Node(id: $id, title: "$title", children: ${children.length} items)';
  }
}

// Виджет дерева
class TreeView extends StatefulWidget {
  final ChapterNode startNode;
  final List<ChapterNode> chapterNodes;

  const TreeView({super.key, required this.chapterNodes, required this.startNode});

  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late Node root;
  Node? selectedNode;
  BigInt? newNode;

  double? _maxWidth;

  @override
  void initState() {
    super.initState();

    print("проверка");
    print(widget.startNode);
    print(widget.chapterNodes);

    root = initializeNode(Node(id: widget.startNode.id, title: "Начало главы") ,widget.startNode, widget.chapterNodes);
  }

  void clearSelection() {
    setState(() {
      selectedNode = null;
    });
  }

  void selectNode(Node node) {
    setState(() {
      selectedNode = node;
    });
  }

  // Change the return type from void to Node
  Node initializeNode(Node node, ChapterNode startNode, List<ChapterNode> nodes) {

    print("aормируем список");
    print(node);
    print(startNode);
    print(nodes);

    // Инициализируем базовые поля узла
    node.id = startNode.id;
    node.title = startNode.slug;

    print(startNode.branching.flag);
    print(startNode.branching.condition.isNotEmpty);

    // Если есть флаг ветвления, создаем детей рекурсивно
    if (startNode.branching.flag && startNode.branching.condition.isNotEmpty) {
      print("зашли");
      node.children = _initializeChildren(startNode, nodes);
    } else {
      node.children = [];
    }

    print("заполненный узел");
    print(node);

    return node; // Возвращаем заполненный узел
  }

  Future<void> initializeChapterNodeById(String nodeId) async {
    try {
      print("hhhhhhhhhhh");
      final ChapterNode? nodes = await getNodeById(safeBigIntParse(nodeId));
      newNode = nodes?.id!;
    } catch (e) {
      print('Ошибка при инициализации chapterNode: $e');
      newNode = null;
      rethrow;
    }
  }

  static BigInt safeBigIntParse(String? value) {
    if (value == null || value.isEmpty) {
      return BigInt.zero;
    }
    try {
      return BigInt.parse(value);
    } catch (e) {
      print('Ошибка парсинга BigInt: $value - $e');
      return BigInt.zero;
    }
  }

// Вспомогательная функция для создания дочерних узлов
  List<Node> _initializeChildren(ChapterNode chapterNode, List<ChapterNode> nodes) {
    List<Node> children = [];

    // Для каждого условия ветвления создаём новый узел
    for (final entry in chapterNode.branching.condition.entries) {
      // Находим ChapterNode по id из условия
      final childChapter = nodes.firstWhereOrNull(
              (node) => node.id == entry.value
      );

      if (childChapter != null) {
        Node newNode = Node.empty(entry.value, entry.key);
        initializeNode(newNode, childChapter, nodes); // Рекурсивный вызов
        children.add(newNode);
      }
    }

    return children;
  }

  void _addChildren(Node node) async {
    List<TextEditingController> controllers = [];
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (controllers.isEmpty) {
              controllers.add(TextEditingController());
            }
            return AlertDialog(
              title: const Text('Добавить дочерние узлы'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controllers[0],
                      decoration: const InputDecoration(
                        labelText: 'Заголовок узла',
                        hintText: 'Введите название узла',
                      ),
                    ),
                    ...List.generate(
                      controllers.length - 1,
                      (index) => TextField(
                        controller: controllers[index + 1],
                        decoration: const InputDecoration(
                          labelText: 'Заголовок узла',
                          hintText: 'Введите название узла',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('+ Добавить поле'),
                  onPressed: () {
                    setState(() {
                      controllers.add(TextEditingController());
                    });
                  },
                ),
                TextButton(
                  child: const Text('Добавить'),
                  onPressed: () {
                    final titles = controllers
                        .map((ctrl) => ctrl.text.trim())
                        .where((title) => title.isNotEmpty)
                        .toList();
                    if (titles.isNotEmpty) {
                      setState(() {
                        for (var i = 0; i < titles.length; i++) {
                          node.children.add(Node(
                            id: newNode!,
                            title: titles[i],
                          ));
                        }
                      });
                    }
                    clearSelection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Node? _findParentNode(Node currentNode, Node targetNode) {
    if (currentNode.children.contains(targetNode)) {
      return currentNode;
    }
    for (final child in currentNode.children) {
      final found = _findParentNode(child, targetNode);
      if (found != null) return found;
    }
    return null;
  }

  bool checkIfTextFits(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    // Проверяем, превышает ли ширина текста максимально допустимую
    return textPainter.size.width > maxWidth;
  }

  void _deleteNode(Node node) {
    setState(() {
      clearSelection();
      final parent = _findParentNode(root, node);
      if (parent != null) {
        parent.children.remove(node);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Дерево истории',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Добавляем горизонтальную прокрутку
              child: Container(
                width: MediaQuery.of(context).size.width, // Фиксируем ширину
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TreeNode(
                        node: root,
                        onNodeTap: _addChildren,
                        onDeleteNode: _deleteNode,
                        onSelectNode: selectNode,
                        selectedNode: selectedNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет для отдельного узла дерева
class TreeNode extends StatefulWidget {
  final Node node;
  final Function(Node) onNodeTap;
  final Function(Node) onDeleteNode;
  final Function(Node)? onSelectNode;
  final Node? selectedNode;

  const TreeNode({
    Key? key,
    required this.node,
    required this.onNodeTap,
    required this.onDeleteNode,
    this.onSelectNode,
    this.selectedNode,
  }) : super(key: key);

  @override
  _TreeNodeState createState() => _TreeNodeState();
}

class _TreeNodeState extends State<TreeNode> {
  bool _isExpanded = true;
  bool _isHovered = false;

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: Text(
              'Вы уверены, что хотите удалить узел "${widget.node.title}" и все его дочерние элементы?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Удалить'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                widget.onDeleteNode(widget.node);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedNode?.id == widget.node.id;

    return MouseRegion(
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onSelectNode?.call(widget.node);
            },
            child: Container(
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : _isHovered
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.transparent,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => widget.onNodeTap(widget.node),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _showDeleteConfirmation(),
                  ),
                  Expanded(
                    child: Text(
                      widget.node.title,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && widget.node.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 64.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.node.children.map((child) => TreeNode(
                        node: child,
                        onNodeTap: widget.onNodeTap,
                        onDeleteNode: widget.onDeleteNode,
                        onSelectNode: widget.onSelectNode,
                        selectedNode: widget.selectedNode,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
