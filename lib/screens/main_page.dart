import 'dart:convert';
import 'dart:math';

import 'package:administration_tool/backend_clients/requests/create_request.dart';
import 'package:administration_tool/models/admin.dart';
import 'package:administration_tool/screens/character.dart';
import 'package:flutter/material.dart';

import '../backend_clients/chapter/create_chapter.dart';
import '../backend_clients/chapter/get_chapter_list.dart';
import '../backend_clients/character/create_character.dart';
import '../backend_clients/character/get_characters.dart';
import '../backend_clients/node/get_node_by_id.dart';
import '../backend_clients/requests/approve_request.dart';
import '../backend_clients/requests/get_requests.dart';
import '../backend_clients/requests/reject_request.dart';
import '../models/chapter.dart';
import '../models/characters.dart';
import '../models/node.dart';
import '../models/request.dart';
import 'authorization.dart';
import 'chapter.dart';

// Главный экран приложения
class DashboardScreen extends StatefulWidget {
  final Admin admin;

  const DashboardScreen({
    Key? key,
    required this.admin,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Состояние для отслеживания выбранной опции в левой панели
  String selectedOption = 'chapters';

  // Данные для глав, запросов и персонажей
  List<Chapter> chapters = [];

  List<Requests> requests = [];

  // Добавляем список персонажей
  List<Character> characters = [];

  ChapterNode? chapterNode;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _loadCharacters();
    _loadRequests();

    // Добавляем слушатель для обновления при возврате
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Проверяем, вернулись ли мы назад
      if (ModalRoute.of(context)?.isCurrent != true) {
        reloadData();
      }
    });
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;

    // Обновляем данные при возврате на экран
    if (ModalRoute.of(context)?.isCurrent == true) {
      reloadData();
    }
  }

  void reloadData() {
    _loadChapters();
    _loadCharacters();
    _loadRequests();
  }

  bool isLoading = false;

  String getDescription(Requests request) {
    var reqChapterId = request.requestedChapterId;
    switch (request.type) {
      case 0:
        return 'Запрос на получение статуса суперадмина для ';
      case 1:
        return 'Запрос на публикацию главы $reqChapterId';
      case 2:
        return 'Запрос на регистрацию';
      case 3:
        return 'Запрос удаление главы $reqChapterId';
      default:
        return 'Неизвестный тип запроса';
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loadedRequests = await getRequestsByUserId(widget.admin.id);
      setState(() {
        requests = loadedRequests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке запросов'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadChapters() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userId = widget.admin.id;
      final loadedChapters = await getChaptersByUserId(userId);
      print("главы");
      setState(() {
        chapters = loadedChapters;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке глав'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void removeRequestAtIndex(int index) {
    setState(() {
      requests = List.from(requests)..removeAt(index);
    });
  }

  Future<void> _loadCharacters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedCharacters = await getCharactersByUserId();
      setState(() {
        characters = loadedCharacters;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при загрузке персонажей'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final ButtonStyle unifiedButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide.none,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.transparent,
    foregroundColor: Colors.black,
    textStyle: const TextStyle(fontSize: 16),
  );

  String convertToUtf8(String input) {
    List<int> bytes = input.codeUnits;
    return utf8.decode(bytes);
  }

  void debugStatus() {
    print('Текущий статус админа: ${widget.admin.adminStatus}');
    print('Текущая выбранная опция: $selectedOption');
    print('Состояние виджета: ${mounted ? 'mounted' : 'unmounted'}');
  }

  Future<ChapterNode?> initializeChapterNode(String nodeId) async {
    print("gопытка получить startNode");
    print(nodeId);
    try {
      final ChapterNode? nodes = await getNodeById(safeBigIntParse(nodeId));
      print("получено начальный узел");
      print(nodes);
      chapterNode = nodes;
      return nodes;
    } catch (e) {
      print('Ошибка при инициализации chapterNode: $e');
      chapterNode = null;
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

  // Добавьте этот код для отладки
  void debugText(String? text) {
    if (text == null) {
      print('Текст равен null');
      return;
    }

    print('--- Отладочная информация ---');
    print('Длина текста: ${text.length}');
    print('Кодировка: ${text.codeUnits}');
    print(
        'UTF-8 байты: ${text.codeUnits.map((b) => b.toRadixString(2).padLeft(8, '0')).join(' ')}');
    print('Тип данных: ${text.runtimeType}');
    print('---------------------------');
  }

  String getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Черновик';
      case 2:
        return 'На проверке';
      case 3:
        return 'Опубликовано';
      default:
        return '';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1: // Черновик
      case 2: // На проверке
        return Colors.grey;
      case 3: // Опубликовано
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugStatus();
    return Scaffold(
      body: Row(
        children: [
          // Левая панель
          Container(
            width: 250,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey),
              ),
            ),
            child: Column(
              children: [
                // Верхняя часть с текстом и кнопками
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convertToUtf8(widget.admin.name),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // Кнопка "Главы"
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedOption = 'chapters';
                          });
                        },
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
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Главы',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // Кнопка "Запросы"
                      ElevatedButton(
                        onPressed: () {
                          if (widget.admin.adminStatus == 0) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Недостаточно прав'),
                                content: const Text(
                                    'У вас недостаточно прав для просмотра запросов'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final bool? confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Запрос статуса суперадмина'),
                                          content: const Text(
                                              'Вы уверены что хотите отправить запрос на получение статуса суперадмина?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                  'Запросить доступ'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        // Здесь добавьте логику отправки запроса на суперадмин
                                        // Например:
                                        try {
                                          createRequest(CreateRequestRequest(
                                              requestingAdminId:
                                                  widget.admin.id.toString(),
                                              type: 0));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Запрос на получение статуса суперадмина отправлен'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Ошибка при отправке запроса: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Запросить доступ'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() => selectedOption = 'requests');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Запросы',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      // Кнопка "Персонажи"
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedOption = 'characters';
                          });
                        },
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
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Персонажи',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Нижняя секция с иконкой выхода
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      tooltip: 'Выйти',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Правая часть с контентом
          Expanded(
            child: Column(
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    selectedOption == 'chapters'
                        ? 'Главы'
                        : selectedOption == 'requests'
                            ? 'Запросы'
                            : 'Персонажи',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // В методе build
                if (selectedOption == 'chapters' ||
                    selectedOption == 'characters')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedOption == 'chapters') {
                          try {
                            final request = CreateChapterRequest(
                                author: widget.admin.id.toString());
                            final newChapter = await createChapter(request);

                            setState(() {
                              chapters.add(newChapter);
                            });

                            // Добавляем автоматическое обновление страницы
                            Future.delayed(Duration.zero, () {
                              if (mounted) {
                                _loadChapters();
                              }
                            });
                          } catch (e) {
                            print('Ошибка при создании главы: $e');
                            // Здесь можно добавить показ ошибки пользователю
                          }
                        } else {
                          final NewCharacterData? character =
                              await showDialog<NewCharacterData>(
                            context: context,
                            builder: (context) => CharacterDialog(),
                          );

                          if (character != null) {
                            setState(() {
                              characters.add(Character(
                                id: character.id,
                                name: character.name,
                                // Используем введенное имя
                                slug: character.slug,
                                // Используем введенный slug
                                color: '#FFFFFF',
                              ));
                            });

                            Future.delayed(Duration.zero, () {
                              if (mounted) {
                                _loadCharacters();
                              }
                            });
                          }
                        }
                      },
                      child: Text(
                          'Добавить ${selectedOption == 'chapters' ? 'главу' : 'персонажа'}'),
                    ),
                  ),
                // Список с контентом
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedOption == 'chapters'
                        ? chapters.length
                        : selectedOption == 'requests'
                            ? requests.length
                            : characters.length,
                    itemBuilder: (context, index) {
                      // существующий код создания элементов списка остается без изменений
                      if (selectedOption == 'chapters') {
                        final Chapter chapter = chapters[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(convertToUtf8(chapter.name)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    getStatusText(chapter.status),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: getStatusColor(chapter.status),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      try {
                                        final bool? confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Подтверждение удаления'),
                                            content: const Text(
                                                'Вы уверены, что хотите удалить эту главу?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Отмена'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Удалить'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          createRequest(
                                            CreateRequestRequest(
                                              requestingAdminId:
                                                  widget.admin.id.toString(),
                                              chapterId:
                                                  chapters[index].id.toString(),
                                              type:
                                                  3, // тип запроса на удаление главы
                                            ),
                                          );

                                          setState(() {
                                            chapters.removeAt(index);
                                          });

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Запрос на удаление главы отправлен'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Ошибка при отправке запроса: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      print("chspters");
                                      print(chapters[index]);
                                      print("chapterNode");
                                      print(chapterNode);
                                      print("startNode");
                                      print(
                                          chapters[index].startNode.toString());

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FutureBuilder<ChapterNode?>(
                                            future: initializeChapterNode(
                                                chapters[index]
                                                    .startNode
                                                    .toString()),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }

                                              return ChapterScreen(
                                                chapter: chapters[index],
                                                chapterNode: snapshot.data!,
                                                admin: widget.admin.id,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (selectedOption == 'requests') {
                        if (widget.admin.adminStatus == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                    'Запрос от ${requests[index].requestingAdmin}'),
                                children: [
                                  ListTile(
                                    title:
                                        Text(getDescription(requests[index])),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: () async {
                                            final bool? confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Подтверждение'),
                                                content: const Text(
                                                    'Вы уверены что хотите одобрить запрос?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Отмена'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      try {
                                                        final requestId =
                                                            requests[index].id;
                                                        bool success =
                                                            await approveRequest(
                                                                requestId);

                                                        if (success) {
                                                          removeRequestAtIndex(
                                                              index);
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            'Ошибка при утверждении запроса: $e');
                                                      }
                                                    },
                                                    child: const Text(
                                                        'Подтвердить'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              setState(() {
                                                requests.removeAt(index);
                                              });
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () async {
                                            final bool? confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Подтверждение'),
                                                content: const Text(
                                                    'Вы уверены что хотите отказать в запросе?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Отмена'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      try {
                                                        final requestId =
                                                            requests[index].id;
                                                        bool success =
                                                            await rejectRequest(
                                                                requestId);

                                                        if (success) {
                                                          removeRequestAtIndex(
                                                              index);
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            'Ошибка при отклонении запроса: $e');
                                                      }
                                                    },
                                                    child: const Text(
                                                        'Подтвердить'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              setState(() {
                                                requests.removeAt(index);
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      } else {
                        return CharacterItem(
                          character: characters[index],
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CharacterEditor(
                                    character: characters[index]),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CharacterItem extends StatelessWidget {
  final Character character;
  final VoidCallback? onEdit;

  static Color safeColorParse(String? value) {
    if (value == null || value.isEmpty) {
      return Colors.transparent;
    }

    String hex = value.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      print('Ошибка парсинга цвета: $value - $e');
      return Colors.transparent;
    }
  }

  const CharacterItem({
    Key? key,
    required this.character,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: safeColorParse(character.color),
                ),
              ),
              title: Text(character.name),
              subtitle: Text(
                character.slug,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            ),
          ],
        ));
  }
}

BigInt generateRandomBigIntFromTime() {
  // Получаем текущее время в микросекундах
  final currentTime = DateTime.now().microsecondsSinceEpoch;

  // Создаем BigInt из времени
  BigInt timeBigInt = BigInt.from(currentTime);

  // Добавляем случайный сдвиг битов
  final random = Random.secure();
  final shift = random.nextInt(32);

  // Сдвигаем биты влево и вправо для создания большего разнообразия
  final shiftedLeft = timeBigInt << shift;
  final shiftedRight = shiftedLeft >> (shift / 2).round();

  return shiftedRight;
}

class CharacterDialog extends StatefulWidget {
  @override
  _CharacterDialogState createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<CharacterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создание персонажа'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя персонажа',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите имя персонажа';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите slug';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final characterId = await createCharacter(
                  _nameController.text,
                  _slugController.text,
                );

                // Проверяем, что id не null
                if (characterId == null) {
                  throw Exception('ID персонажа не получен');
                }

                NewCharacterData data = NewCharacterData(
                  id: characterId,
                  // Теперь безопасно используем non-nullable значение
                  name: _nameController.text,
                  slug: _slugController.text,
                );
                Navigator.pop(context, data);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

class NewCharacterData {
  final BigInt id;
  final String name;
  final String slug;

  NewCharacterData({
    required this.id,
    required this.name,
    required this.slug,
  });
}
