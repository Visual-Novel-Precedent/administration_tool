import 'package:flutter/material.dart';
import 'dart:math';

import 'audio_upload.dart';
import 'character_position_in_node.dart';
import 'event.dart';
import 'image_upload.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TreePainter extends CustomPainter {
  final List<Node> nodes;
  final double maxNodeWidth;

  TreePainter(this.nodes, this.maxNodeWidth);

  double calculateTreeCenterX(List<Node> nodes) {
    double maxX = double.negativeInfinity;
    double minX = double.infinity;
    void traverse(Node node) {
      maxX = max(maxX, node.x);
      minX = min(minX, node.x);
      for (final child in node.children) {
        traverse(child);
      }
    }

    traverse(nodes.first);
    return (maxX + minX) / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final treeCenterX = calculateTreeCenterX(nodes);
    final offsetX = centerX - treeCenterX * size.width;
    canvas.save();
    canvas.translate(offsetX, 0);
    _drawConnections(canvas, size, nodes);
    _drawNodesRecursive(canvas, size, nodes);
    canvas.restore();
  }

  void _drawConnections(Canvas canvas, Size size, List<Node> nodes) {
    for (final node in nodes) {
      for (final child in node.children) {
        final startX = size.width * node.x;
        final startY = size.height * node.y;
        final endX = size.width * child.x;
        final endY = size.height * child.y;
        final angle = atan2(endY - startY, endX - startX);

        final x = size.width * node.x;
        final y = size.height * node.y;

        // Сохраняем глобальные координаты узла
        node.globalPosition = Offset(x, y);

        const offset = 15;

        final startXOffset = startX + offset * cos(angle);
        final startYOffset = startY + offset * sin(angle);
        final endXOffset = endX - offset * cos(angle);
        final endYOffset = endY - offset * sin(angle);
        canvas.drawLine(
          Offset(startXOffset, startYOffset),
          Offset(endXOffset, endYOffset),
          Paint()
            ..color = Colors.grey
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
      _drawConnections(canvas, size, node.children);
    }
  }

  double calculateTreeHeight(BoxConstraints constraints) {
    double maxHeight = 0;
    void traverse(Node node) {
      double currentHeight = node.y;
      for (final child in node.children) {
        currentHeight = max(currentHeight, child.y);
        traverse(child);
      }
      maxHeight = max(maxHeight, currentHeight);
    }

    traverse(nodes.first);
    return maxHeight * constraints.maxHeight * 2;
  }

  void _drawNodesRecursive(Canvas canvas, Size size, List<Node> nodes) {
    for (final node in nodes) {
      final x = size.width * node.x;
      final y = size.height * node.y;

      // Рисуем прямоугольник с закругленными углами
      final rect = Rect.fromLTWH(
          x - 40, // Увеличен отступ для текста
          y - 20,
          80,     // Ширина узла
          40      // Высота узла
      );

      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );

      // Рисуем текст внутри узла
      final textSpan = TextSpan(
        text: node.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 80,
        maxWidth: 80,
      );

      final textOffset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      _drawNodesRecursive(canvas, size, node.children);
    }
  }

  Node? findNodeAtPosition(List<Node> nodes, double x, double y) {
    Node? findNode(Node node) {
      if (node.globalPosition != null) {
        final nodeX = node.globalPosition!.dx;
        final nodeY = node.globalPosition!.dy;

        // Проверяем попадание в прямоугольник узла с учётом размеров
        if ((nodeX - x).abs() < 40 && (nodeY - y).abs() < 20) {
          return node;
        }
      }

      for (final child in node.children) {
        final found = findNode(child);
        if (found != null) return found;
      }
      return null;
    }

    return findNode(nodes.first);
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) => true;
}

class ChapterScreen extends StatefulWidget {
  final String chapterTitle;

  const ChapterScreen({super.key, required this.chapterTitle});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  List<Node> nodes = [
    Node(
      id: 1,
      title: 'Начало',
      x: 0.5,
      y: 0.1,
      children: [],
    ),
  ];
  double maxNodeWidth = 1.0;

  // Добавляем состояние для заголовка
  String _chapterTitle = '';

  @override
  void initState() {
    super.initState();
    _chapterTitle = widget.chapterTitle;
  }

  // Метод для изменения заголовка
  void updateChapterTitle(String newTitle) {
    setState(() {
      _chapterTitle = newTitle;
    });
  }
  final _random = Random();

  int generateRandomId() {
    return _random.nextInt(1000);
  }

  void addNodesToLeaf(Node node, int count) {
    final baseSpacing = 0.2;
    final levelSpacing = 0.2;
    double minX = node.x - (count - 1) * baseSpacing / 2;
    final newNodes = List.generate(count, (index) {
      return Node(
        id: generateRandomId(),
        title: 'Новый узел ${node.id + generateRandomId()}',
        x: minX + index * baseSpacing,
        y: node.y + levelSpacing,
        children: [],
      );
    });
    node.children = newNodes;

    // Выводим информацию в консоль
    debugPrint('=== Добавление узлов ===');
    debugPrint('Список всех узлов:');
    _printAllNodes(nodes);
    debugPrint('Выбранный узел для добавления детей:');
    debugPrint('ID: ${node.id}, Заголовок: ${node.title}, Координаты: (${node.x}, ${node.y})');

    setState(() {
      TreeLayout.layoutTree(nodes.first);
      final oldWidth = maxNodeWidth;
      maxNodeWidth = calculateMaxWidth(nodes, 1.0);
      final scaleFactor = maxNodeWidth / oldWidth;
      maxNodeWidth = oldWidth * 2 * scaleFactor;

      // Пересчитываем глобальные координаты после изменения макета
      _updateGlobalPositions(nodes);
    });
  }

  void _updateGlobalPositions(List<Node> nodes) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    void updatePosition(Node node) {
      final localPosition = Offset(node.x * renderBox.size.width,
          node.y * renderBox.size.height);
      node.globalPosition = renderBox.localToGlobal(localPosition);

      for (final child in node.children) {
        updatePosition(child);
      }
    }

    updatePosition(nodes.first);
  }

  void _printAllNodes(List<Node> nodes) {
    void printNode(Node node, int level) {
      debugPrint('${'  ' * level}ID: ${node.id}, Заголовок: ${node.title}, Координаты: (${node.x}, ${node.y})');
      for (final child in node.children) {
        printNode(child, level + 1);
      }
    }
    printNode(nodes.first, 0);
  }

  void _handleTapOnTree(double x, double y) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final containerSize = renderBox.size;

    // Get the global position of the render box
    final boxPosition = renderBox.localToGlobal(Offset.zero);

    // Calculate the local position relative to the render box
    final normalizedX = (x - boxPosition.dx) / containerSize.width;
    final normalizedY = (y - boxPosition.dy) / containerSize.height;

    debugPrint('=== Координаты клика ===');
    debugPrint('Нормализованные координаты: ($normalizedX, $normalizedY)');
    debugPrint('Координаты в контейнере: ($x, $y)');

    Node? clickedNode = findNodeAtPosition(nodes, normalizedX, normalizedY);

    if (clickedNode == null) {
      Node? nearestLeaf = _findNearestLeafNode(nodes, normalizedX, normalizedY);
      if (nearestLeaf != null) {
        showAddNodesDialog(nearestLeaf);
      }
    } else if (clickedNode.children.isEmpty) {
      showAddNodesDialog(clickedNode);
    }
  }

  double calculateMaxWidth(List<Node> nodes, double scaleFactor) {
    double maxWidth = 0;
    void traverse(Node node) {
      double currentWidth = node.x;
      for (final child in node.children) {
        currentWidth = max(currentWidth, child.x);
        traverse(child);
      }
      maxWidth = max(maxWidth, currentWidth);
    }

    traverse(nodes.first);
    return maxWidth * scaleFactor;
  }

  double calculateTreeHeight(BoxConstraints constraints) {
    double maxHeight = 0;
    void traverse(Node node) {
      double currentHeight = node.y;
      for (final child in node.children) {
        currentHeight = max(currentHeight, child.y);
        traverse(child);
      }
      maxHeight = max(maxHeight, currentHeight);
    }

    traverse(nodes.first);
    return maxHeight * constraints.maxHeight * 2;
  }

  void showAddNodesDialog(Node node) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Добавить узлы'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество узлов',
              hintText: 'Введите число',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final count = int.tryParse(controller.text) ?? 0;
                if (count > 0) {
                  addNodesToLeaf(node, count);
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  Node? findNodeAtPosition(List<Node> nodes, double x, double y) {
    Node? findNode(Node node) {
      if ((node.x - x).abs() < 0.05 && (node.y - y).abs() < 0.05) {
        return node;
      }
      for (final child in node.children) {
        final found = findNode(child);
        if (found != null) return found;
      }
      return null;
    }

    return findNode(nodes.first);
  }

  Node? _findNearestLeafNode(List<Node> nodes, double x, double y) {
    Node? nearestLeaf;
    double minDistance = double.infinity;

    void checkNode(Node node) {
      if (node.children.isEmpty) {
        // Используем сумму модулей расстояний вместо евклидова расстояния
        final distance = (node.x - x).abs() + (node.y - y).abs();
        if (distance < minDistance) {
          minDistance = distance;
          nearestLeaf = node;
        }
      }
      for (final child in node.children) {
        checkNode(child);
      }
    }

    for (final node in nodes) {
      checkNode(node);
    }
    return nearestLeaf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _chapterTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final controller =
                            TextEditingController(text: _chapterTitle);

                            return AlertDialog(
                              title: const Text('Редактировать название главы'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Название главы',
                                  hintText: 'Введите новое название',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (controller.text.isNotEmpty) {
                                      updateChapterTitle(controller.text);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Сохранить'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                // Изменено с CrossAxisAlignment.start
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                          fontSize: 16), // Добавлено для увеличения шрифта
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ImageUploadDialog(),
                      );
                    },
                    child: const Text('Фон'),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                          fontSize: 16), // Добавлено для увеличения шрифта
                    ),
                    onPressed: () {
                      debugPrint('Пытаемся показать диалог');
                      showDialog(
                        context: context,
                        builder: (context) => const AudioUploadDialog(),
                      ).then((value) {
                        debugPrint('Диалог закрыт');
                      });
                    },
                    child: const Text('Аудио'),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                          fontSize: 16), // Добавлено для увеличения шрифта
                    ),
                    onPressed: () {
                      debugPrint('Пытаемся показать диалог');
                      showDialog(
                        context: context,
                        builder: (context) => const SceneCharacters(),
                      ).then((value) {
                        debugPrint('Диалог закрыт');
                      });
                    },
                    child: const Text('Персонажи в сцене'),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                          fontSize: 16), // Добавлено для увеличения шрифта
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: SceneEditor(),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('События'),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                          fontSize: 16), // Добавлено для увеличения шрифта
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CommentDialog(),
                      );
                    },
                    child: const Text('Комментарий'),
                  ),
                ],
              )
            ]),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                    final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                    _handleTapOnTree(localPosition.dx / renderBox.size.width,
                        localPosition.dy / renderBox.size.height);
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: RawScrollbar(
                        thumbColor: Colors.grey.withOpacity(0.5),
                        thickness: 8,
                        radius: Radius.circular(32),
                        child: CustomPaint(
                          painter: TreePainter(nodes, maxNodeWidth),
                          child: SizedBox(
                            width: maxNodeWidth * constraints.maxWidth * 1.5,
                            height: calculateTreeHeight(constraints),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class Node {
  final int id;
  final String title;
  double x;
  double y;
  List<Node> children;
  Offset? globalPosition; // Добавляем поле для хранения глобальных координат

  Node({
    required this.id,
    required this.title,
    required this.x,
    required this.y,
    this.children = const [],
    this.globalPosition,
  });
}


class TreeLayout {
  static void layoutTree(Node root, {double yPad = 0.15}) { // Увеличили с 0.1 до 0.15
    root.y = 0;
    double layoutNode(Node node, double xBound, double y) {
      if (node.children.isEmpty) {
        node.x = xBound;
        return xBound + 0.08; // Увеличили с 0.05 до 0.08
      }

      double xLeft = double.infinity;
      double xRight = double.negativeInfinity;
      double newXBound = xBound;

      for (final child in node.children) {
        final bound = layoutNode(child, newXBound, y + yPad);
        xLeft = min(xLeft, child.x);
        xRight = max(xRight, child.x);
        newXBound = max(newXBound, bound);
      }

      node.x = (xLeft + xRight) / 2;
      node.y = y;
      return newXBound;
    }

    layoutNode(root, 0.5, 0);
  }
}

class CommentDialog extends StatefulWidget {
  const CommentDialog({super.key});

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый комментарий'),
      content: TextField(
        maxLines: null,
        expands: true,
        minLines: null,
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Текст комментария',
          hintText: 'Введите ваш комментарий здесь...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              // Здесь можно добавить логику сохранения комментария
              debugPrint('Сохранен комментарий: ${controller.text}');
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
