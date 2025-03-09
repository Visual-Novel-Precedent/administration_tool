import 'package:flutter/material.dart';

import '../backend_clients/chapter/update_chapter.dart';
import '../backend_clients/node/create_node.dart';
import '../backend_clients/node/get_node_by_id.dart';
import '../backend_clients/node/get_nodes_by_chapter_id.dart';
import '../backend_clients/node/update_node.dart';
import '../models/chapter.dart';
import '../models/node.dart';
import 'package:collection/collection.dart';

import 'chapter.dart';

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

  List<BigInt> collectAllIds() {
    final ids = <BigInt>[id]; // Начинаем с id текущего узла

    // Рекурсивно добавляем id всех потомков
    for (final child in children) {
      ids.addAll(child.collectAllIds());
    }

    return ids;
  }
}

// Виджет дерева
class TreeView extends StatefulWidget {
  final Chapter chapter;
  final ChapterNode startNode;
  final List<ChapterNode> chapterNodes;
  final BigInt admin;

  const TreeView(
      {super.key,
      required this.chapterNodes,
      required this.startNode,
      required this.chapter,
      required this.admin});

  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late Node root;
  Node? selectedNode;
  BigInt? newNode;

  Chapter? chapter;
  List<ChapterNode>? chapterNodes;

  @override
  void initState() {
    super.initState();

    chapter = widget.chapter;
    chapterNodes = widget.chapterNodes;

    print("проверка");
    print(widget.startNode);
    print(widget.chapterNodes);

    _verifyNodes(chapterNodes!);

    late ChapterNode st;
    widget.chapterNodes.forEach((element) {
      if (element.id == widget.chapter.startNode) {
        st = element;
      }
    });

    print("ghишедшие узлы");
    print(widget.chapterNodes);
    root = initializeNode(
        Node(id: widget.chapter.startNode, title: "Начало главы"),
        st,
        widget.chapterNodes);

    print(root);

    selectedNode = findNode(root, widget.startNode.id);
  }

  void clearSelection() {
    setState(() {
      selectedNode = null;
    });
  }

  Node? findNode(Node root, BigInt targetId) {
    // Проверяем текущий узел
    if (root.id == targetId) {
      return root;
    }

    // Проверяем дочерние узлы
    for (final child in root.children) {
      final found = findNode(child, targetId);
      if (found != null) {
        return found;
      }
    }

    return null;
  }

  void selectNode(Node node) {
    print('Выбранный узел: ${node.title}, ID: ${node.id}');

    setState(() {
      selectedNode = node;
    });

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            FutureBuilder<ChapterNode?>(
          future: initializeChapterNode(node.id.toString()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Добавляем проверку при возврате
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                selectedNode = node;
              });
            });

            print("snapshot.data!");
            print(snapshot.data!);

            return ChapterScreen(
              chapter: widget.chapter,
              chapterNode: snapshot.data!,
              admin: widget.admin,
            );
          },
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<ChapterNode?> initializeChapterNode(String nodeId) async {
    print("gопытка получить startNode");
    print(nodeId);
    try {
      final ChapterNode? nodes = await getNodeById(safeBigIntParse(nodeId));
      print("получено начальный узел");
      print(nodes);
      return nodes;
    } catch (e) {
      print('Ошибка при инициализации chapterNode: $e');
      rethrow;
    }
  }

  // Change the return type from void to Node
  Node initializeNode(
      Node node, ChapterNode startNode, List<ChapterNode> nodes) {
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

  void _verifyNodes(List<ChapterNode> nodes) {
    final nodeIds = nodes.map((n) => n.id).toSet();
    print("Доступные узлы: $nodeIds");

    // Проверка отсутствующих узлов
    final missingIds = [
      safeBigIntParse('114131118735455260'),
      safeBigIntParse('114131118733240320'),
      safeBigIntParse('114131118739534860')
    ];

    for (final id in missingIds) {
      if (!nodeIds.contains(id)) {
        print("Отсутствует узел с ID: $id");
      }
    }
  }

// Вспомогательная функция для создания дочерних узлов
  List<Node> _initializeChildren(
      ChapterNode chapterNode, List<ChapterNode> nodes) {
    List<Node> children = [];
    print("=== Начало обработки узла ===");
    print("ID текущего узла: ${chapterNode.id}");
    print("Параметры ветвления: ${chapterNode.branching.condition}");

    // Для каждого условия ветвления создаём новый узел
    for (final entry in chapterNode.branching.condition.entries) {
      print("\nОбработка условия ветвления:");
      print("Ключ: ${entry.key}, Значение: ${entry.value}");

      // Находим ChapterNode по id из условия
      final childChapter =
          nodes.firstWhereOrNull((node) => node.id == entry.value);
      print("Найден дочерний узел: $childChapter");

      if (childChapter != null) {
        Node newNode = Node.empty(entry.value, entry.key);
        print("Создан новый узел: $newNode");

        // Рекурсивное построение поддерева
        if (childChapter.branching.flag &&
            childChapter.branching.condition.isNotEmpty) {
          print(
              "Начало рекурсивного построения поддерева для узла ${newNode.id}");
          newNode.children = _initializeChildren(childChapter, nodes);
          print(
              "Завершено рекурсивное построение поддерева для узла ${newNode.id}");
          print("Количество дочерних узлов: ${newNode.children.length}");
        }

        children.add(newNode);
        print("Узел добавлен в список детей");
      } else {
        print("Дочерний узел не найден для ID: ${entry.value}");
      }
    }

    print("\n=== Завершение обработки узла ===");
    print("Всего создано дочерних узлов: ${children.length}");
    return children;
  }

  void _addChildren(Node node) async {
    List<TextEditingController> controllers = [TextEditingController()];
    bool shouldRefresh = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                  onPressed: () => Navigator.of(dialogContext)
                      .pop(), // Используем контекст диалога
                ),
                TextButton(
                  child: const Text('+ Добавить поле'),
                  onPressed: () {
                    setDialogState(() {
                      controllers.add(TextEditingController());
                    });
                  },
                ),
                TextButton(
                  child: const Text('Добавить'),
                  onPressed: () async {
                    final titles = controllers
                        .map((ctrl) => ctrl.text.trim())
                        .where((title) => title.isNotEmpty)
                        .toList();

                    print('Количество узлов для добавления: ${titles.length}');
                    print(titles.isNotEmpty);

                    print('Состояние перед добавлением:');
                    print('node.children.length: ${node.children.length}');
                    print('newNode: $newNode');

                    if (titles.isNotEmpty) {
                      setDialogState(() async {
                        shouldRefresh = true;
                        for (var i = 0; i < titles.length; i++) {
                          BigInt newNodeId =
                              await createNode(widget.chapter.id, titles[i]);

                          print("создали новый узел");
                          print(newNodeId);

                          chapterNodes?.forEach((element) async {
                            if (element.id == node.id) {
                              Map<String, BigInt> condition =
                                  element.branching.condition;
                              condition[titles[i]] = newNodeId;

                              Branching br =
                                  Branching(flag: true, condition: condition);

                              element = ChapterNode(
                                id: element.id,
                                slug: element.slug,
                                events: element.events,
                                chapterId: element.chapterId,
                                music: element.music,
                                background: element.background,
                                branching: br,
                                end: element.end,
                                comment: element.comment,
                              );

                              print("Добавили branching");
                              print(element);
                              print(element.branching);

                              try {
                                final success = await updateNode(element);
                                if (success) {
                                  print('Глава успешно обновлена на сервере');
                                }
                              } catch (e) {
                                print('Ошибка при обновлении главы: $e');
                                // Здесь можно добавить обработку ошибки
                              }
                            }
                          });

                          print("Добавляем главы в hcapter");
                          print(chapter?.nodes);

                          chapter?.nodes.add(newNodeId);
                          node.children.add(Node(
                            id: newNodeId,
                            title: titles[i],
                          ));

                          print('Добавлен узел: ${titles[i]}');
                          print(chapter?.nodes);
                          print(newNodeId);
                        }
                      });

                      print("Добавили главы в hcapter");
                      print(chapter?.nodes);

                      // Используем правильный контекст для закрытия диалога
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (shouldRefresh) {
        setState(() {});
      }
    });
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

  void _deleteNode(Node node) async {
    print("=== Начало удаления узла ===");
    print("ID удаляемого узла: ${node.id}");
    print("Заголовок удаляемого узла: ${node.title}");
    print("Количество дочерних узлов: ${node.children.length}");

    clearSelection();
    final parent = _findParentNode(root, node);
    if (parent != null) {
      print("Найден родительский узел: ${parent.title}");
      parent.children.remove(node);
      print("Узел удален из детей родителя");
    }

    chapterNodes?.forEach((element) {
      if (element.id == node.id) {
        print("Удаляем узел из chapterNodes");
        chapterNodes?.remove(element);
      }

      element.branching.condition.forEach((key, value) {
        if (value == node.id) {
          print("Удаляем связь ветвления: $key -> ${node.id}");
          element.branching.condition.remove(key);
        }
      });
    });

    List<BigInt> n = node.collectAllIds();
    print("=== Важно: Количество ID в дереве после удаления: ${n.length} ===");

    chapter = Chapter(
      id: chapter?.id ?? BigInt.from(0),
      name: chapter?.name ?? "",
      startNode: chapter?.startNode ?? BigInt.from(0),
      nodes: n,
      characters: chapter?.characters ?? [],
      status: chapter?.status ?? 0,
      author: chapter?.author ?? BigInt.from(0),
    );

    print("Текущее состояние chapter:");
    print("ID: ${chapter?.id}");
    print("Имя: ${chapter?.name}");
    print("Начальный узел: ${chapter?.startNode}");
    print("Количество узлов: ${chapter?.nodes?.length}");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final request = UpdateChapterRequest(
          id: chapter!.id,
          nodes: chapter?.nodes,
          updateAuthorId: BigInt.from(1), // ID текущего пользователя
        );

        print("=== Создание запроса ===");
        print("ID главы: ${request.id}");
        print("Количество узлов для обновления: ${request.nodes?.length}");

        print('Выполняем запрос на обновление главы');
        final stopwatch = Stopwatch()..start();

        final success = await updateChapter(request);
        final duration = stopwatch.elapsedMilliseconds;

        if (success) {
          print('Глава успешно обновлена на сервере');
          print("Время выполнения запроса: ${duration}ms");
        } else {
          print("Ошибка при обновлении главы");
        }
      } catch (e) {
        print('=== Ошибка при обновлении главы ===');
        print('Тип ошибки: ${e.runtimeType}');
        print('Сообщение ошибки: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении главы: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        chapter = chapter;
        chapterNodes = chapterNodes;
      });
    });

    // Сначала обновляем состояние

    print("=== После обновления состояния ===");
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
              scrollDirection: Axis.horizontal,
              // Добавляем горизонтальную прокрутку
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
