import 'dart:convert';
import 'dart:typed_data';

import 'package:administration_tool/screens/tree.dart';
import 'package:flutter/material.dart';
import 'package:windows1251/windows1251.dart';
import 'dart:math';

import '../backend_clients/chapter/update_chapter.dart';
import '../backend_clients/character/get_characters.dart';
import '../backend_clients/media/get_media.dart';
import '../backend_clients/node/get_node_by_id.dart';
import '../backend_clients/node/get_nodes_by_chapter_id.dart';
import '../backend_clients/node/update_node.dart';
import '../backend_clients/requests/create_request.dart';
import '../models/chapter.dart';
import '../models/characters.dart';
import '../models/node.dart';
import 'audio_upload.dart';
import 'chapter.dart';
import 'character_position_in_node.dart';
import 'event.dart';
import 'image_upload.dart';
import 'dart:convert';

class ChapterNodeForUpdate {
  BigInt? id;
  String? slug;
  Map<int, Event>? events;
  BigInt? chapterId;
  BigInt? music;
  BigInt? background;
  Branching? branching;
  EndInfo? end;
  String? comment;

  ChapterNodeForUpdate({
    this.id,
    this.slug,
    this.events,
    this.chapterId,
    this.music,
    this.background,
    this.branching,
    this.end,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'Id': id.toString(),
      'Slug': slug,
      'Events':
          events?.map((key, value) => MapEntry(key.toString(), value.toJson())),
      'ChapterId': chapterId.toString(),
      'Music': music.toString(),
      'Background': background.toString(),
      'Branching': branching?.toJson(),
      'End': end?.toJson(),
      'Comment': comment.toString(),
    };
  }

  @override
  String toString() {
    return 'Node(id: $id, slug: $slug, events: $events, chapterId: $chapterId, '
        'music: $music, background: $background, branching: $branching, end: $end, comment: $comment)';
  }
}

class ChapterScreen extends StatefulWidget {
  final Chapter chapter;
  final ChapterNode chapterNode;
  final BigInt admin;

  const ChapterScreen(
      {super.key,
      required this.chapter,
      required this.chapterNode,
      required this.admin});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  // Добавляем состояние для заголовка
  String _chapterTitle = '';
  List<ChapterNode>? _chapterNodes;
  ChapterNode? chapterNode;
  ChapterNodeForUpdate? chapterNodeForUpdate;
  Uint8List? background;
  Uint8List? audio;
  bool isLoading = false;
  List<Character> characters = [];

  @override
  void initState() {
    print("cgapterNodeddd");
    print(widget.chapterNode);
    super.initState();
    _chapterTitle = widget.chapter.name;
    _loadChapterNodes();
    print("получили узлы");
    print(_chapterNodes);

    initializeChapterNode(widget.chapterNode.id.toString());

    print("инициализировали начальный узел");
    print(chapterNode);

    _initializeBackground();
    _initializeAudio();

    _loadCharacters();
  }

  ChapterNode convertChapterNodeForUpdateToChapterNode(
      ChapterNodeForUpdate? updateNode) {
    if (updateNode == null) {
      return ChapterNode(
        id: BigInt.zero,
        slug: '',
        events: {},
        chapterId: BigInt.zero,
        music: BigInt.zero,
        background: BigInt.zero,
        branching: Branching(flag: false, condition: {}),
        end: EndInfo(flag: false, endResult: '', endText: ''),
        comment: '',
      );
    }

    return ChapterNode(
      id: updateNode.id ?? BigInt.zero,
      slug: updateNode.slug ?? '',
      events: updateNode.events ?? {},
      chapterId: updateNode.chapterId ?? BigInt.zero,
      music: updateNode.music ?? BigInt.zero,
      background: updateNode.background ?? BigInt.zero,
      branching: updateNode.branching ?? Branching(flag: false, condition: {}),
      end: updateNode.end ?? EndInfo(flag: false, endResult: '', endText: ''),
      comment: updateNode.comment ?? '',
    );
  }

  Future<Uint8List> _loadMedia(BigInt id) async {
    try {
      final media = await getMediaById(id.toString());
      if (media?.fileData != null && media!.fileData.isNotEmpty) {
        return media.fileData;
      }
      throw Exception('Пустые данные медиа');
    } catch (e) {
      print('Ошибка при загрузке медиа $id: $e');
      rethrow;
    }
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

  void showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: chapterNodeForUpdate?.comment ?? '',
        );

        return StatefulBuilder(
          builder: (dialogContext, stfSetState) {
            return AlertDialog(
              title: const Text('Редактирование комментария'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                child: TextField(
                  maxLines: null,
                  expands: true,
                  controller: controller,
                  onChanged: (value) {
                    stfSetState(() {});
                  },
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
                      setState(() {
                        chapterNodeForUpdate?.comment = controller.text;
                      });
                      Navigator.pop(context);

                      ChapterNode newNode =
                          convertChapterNodeForUpdateToChapterNode(
                              chapterNodeForUpdate);

                      updateNode(newNode).then((success) {
                        if (success) {
                          print('Узел успешно обновлен с комментарием');
                        } else {
                          print('Ошибка при обновлении узла с комментарием');
                        }
                      }).catchError((e) {
                        print('Ошибка при обновлении узла: $e');
                      });
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _initializeBackground() async {
    try {
      background = await _loadMedia(widget.chapterNode.background);
      setState(() {}); // Обновляем UI после загрузки
    } catch (e) {
      print('Ошибка при загрузке фона: $e');
      rethrow;
    }
  }

  Future<void> _initializeAudio() async {
    try {
      audio = await _loadMedia(widget.chapterNode.music);
      setState(() {}); // Обновляем UI после загрузки
    } catch (e) {
      print('Ошибка при загрузке фона: $e');
      rethrow;
    }
  }

  Future<List<ChapterNode>> _loadChapterNodes() async {
    try {
      final nodes = await processChapterNodes(widget.chapter.id);
      setState(() {
        _chapterNodes = nodes.nodes;
      });
      return nodes.nodes; // Возвращаем List<ChapterNode>
    } catch (e) {
      print('Ошибка при загрузке узлов: $e');
      rethrow;
    }
  }

  Future<void> initializeChapterNode(String nodeId) async {
    print("rrrrrrrrrrrrrr");
    try {
      final ChapterNode? nodes = await getNodeById(safeBigIntParse(nodeId));
      chapterNode = nodes;

      print("chapterNode");
      print(chapterNode);

      chapterNodeForUpdate = ChapterNodeForUpdate(
          id: chapterNode?.id,
          slug: chapterNode?.slug,
          events: chapterNode?.events,
          chapterId: chapterNode?.chapterId,
          music: chapterNode?.music,
          background: chapterNode?.background,
          branching: chapterNode?.branching,
          end: chapterNode?.end,
          comment: chapterNode?.comment);

      print("узел для редактирования");
      print(chapterNodeForUpdate);
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

  Future<ChapterNodes> processChapterNodes(BigInt chapterId) async {
    print("leeeetsGoooooooo");
    try {
      final nodes = await getNodesByChapterId(chapterId);

      print('Получено узлов: ${nodes.nodes.length}');
      print('ID начального узла: ${nodes.startNode?.id}');

      final startNode = nodes.startNode;
      if (startNode != null) {
        print('Слаг начального узла: ${startNode.slug}');
        print('События начального узла: ${startNode.events.length}');
      }

      print("processChapterNodes");
      print(nodes);

      return nodes;
    } catch (e) {
      print('Ошибка: $e');
      rethrow;
    }
  }

  Future<Map<int, Event>> showSceneEditorDialog(BuildContext context) async {
    final Map<int, Event>? result = await showDialog<Map<int, Event>>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: SceneEditor(
              characters: characters,
              events: chapterNode?.events ?? {},
            ),
          ),
        );
      },
    );

    return result ?? {};
  }

  String convertToUtf8(String input) {
    try {
      // Преобразуем строку в байты
      List<int> bytes = input.codeUnits;

      // Попытка декодирования как UTF-8
      try {
        return utf8.decode(bytes);
      } catch (e) {
        // Если не получилось, пробуем использовать windows-1251
        return windows1251.decode(bytes);
      }
    } catch (e) {
      print('Ошибка конвертации строки: $e');
      return input;
    }
  }

  void showEndDialog() {
    print("rонцовка");
    print(widget.chapterNode.end);
    showDialog(
      context: context,
      builder: (context) {
        final endResultController = TextEditingController(
          text: chapterNodeForUpdate?.end?.endResult ?? '',
        );
        final endTextController = TextEditingController(
          text: chapterNodeForUpdate?.end?.endText ?? '',
        );

        return StatefulBuilder(
          builder: (dialogContext, stfSetState) {
            return AlertDialog(
              title: const Text('Настройка концовки'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚠️ Важное предупреждение: если вы отметите концовку, то все события в этом узле не сохранятся',
                      style: TextStyle(
                        color: Colors.black12,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Это концовка'),
                    value: chapterNodeForUpdate?.end?.flag,
                    onChanged: (bool? value) {
                      stfSetState(() {
                        if (chapterNodeForUpdate?.end?.flag == false) {
                          value = true;
                          chapterNodeForUpdate?.end = EndInfo(
                            flag: value ?? true,
                            endResult: '',
                            endText: '',
                          );
                        } else {
                          value = false;
                          chapterNodeForUpdate?.end = EndInfo(
                            flag: value ?? false,
                            endResult: '',
                            endText: '',
                          );
                        }
                      });
                    },
                  ),
                  if ((chapterNodeForUpdate?.end?.flag ?? false))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: endResultController,
                          decoration: const InputDecoration(
                            labelText: 'Результат концовки',
                            hintText: 'Введите результат',
                          ),
                          onChanged: (value) {
                            stfSetState(() {
                              chapterNodeForUpdate?.end = EndInfo(
                                flag: chapterNodeForUpdate?.end?.flag ?? true,
                                endResult: value,
                                endText:
                                    chapterNodeForUpdate?.end?.endText ?? '',
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: endTextController,
                          decoration: const InputDecoration(
                            labelText: 'Текст концовки',
                            hintText: 'Введите текст',
                          ),
                          onChanged: (value) {
                            stfSetState(() {
                              chapterNodeForUpdate?.end = EndInfo(
                                flag: chapterNodeForUpdate?.end?.flag ?? true,
                                endResult:
                                    chapterNodeForUpdate?.end?.endResult ?? '',
                                endText: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    if (chapterNodeForUpdate?.end?.flag == true) {
                      if (endResultController.text.trim().isEmpty ||
                          endTextController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Пожалуйста, заполните все поля для концовки'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    chapterNodeForUpdate?.events = {};

                    ChapterNode newNode =
                        convertChapterNodeForUpdateToChapterNode(
                            chapterNodeForUpdate);
                    print("изменяем состояние на концовку");
                    print(newNode);

                    updateNode(newNode).then((success) {
                      print("запрос на концоыку отправлен");
                      if (success) {
                        setState(() {
                          chapterNode = newNode;
                        });
                        Navigator.pop(context);
                      }
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при обновлении узла: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
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
                        convertToUtf8(_chapterTitle),
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
                            final controller = TextEditingController(
                                text: convertToUtf8(_chapterTitle));
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
                                  onPressed: () async {
                                    if (controller.text.isNotEmpty) {
                                      var curName =
                                          utf8.encode(controller.text);
                                      try {
                                        final encodedText =
                                            utf8.encode(controller.text);
                                        final decodedText =
                                            utf8.decode(encodedText);

                                        final request = UpdateChapterRequest(
                                          id: widget.chapter!.id,
                                          name: decodedText,
                                          updateAuthorId: BigInt.from(1),
                                        );

                                        final success =
                                            await updateChapter(request);
                                        if (success) {
                                          setState(() {
                                            _chapterTitle = controller.text;
                                          });
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Ошибка при обновлении названия: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
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
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      // Удаляем проверку на null
                      showDialog<String>(
                        context: context,
                        builder: (context) => ImageUploadDialog(
                          background: background,
                        ),
                      ).then((newImage) {
                        if (newImage != null) {
                          print("нолучили новую картинку");
                          print(newImage);

                          ChapterNode newNode =
                              convertChapterNodeForUpdateToChapterNode(
                            chapterNodeForUpdate,
                          );

                          newNode.background = safeBigIntParse(newImage);

                          print(newNode);

                          updateNode(newNode).then((success) {
                            if (success) {
                              print('узел успещно обновлен');
                              chapterNode = newNode;
                            } else {
                              print('Ошибка при обновлении узла');
                            }
                          }).catchError((e) {
                            print('Ошибка при обновлении узла: $e');
                          });

                          _loadMedia(safeBigIntParse(newImage))
                              .then((newImageData) {
                            setState(() {
                              print("hhhhhhhh");
                              chapterNodeForUpdate?.background =
                                  safeBigIntParse(newImage);
                              background = newImageData;
                            });
                          });
                        }
                      });
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
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      // Убедимся, что диалог открывается
                      print('Нажата кнопка "Аудио"');
                      showDialog<String>(
                        context: context,
                        builder: (context) => AudioUploadDialog(
                          existingAudio:
                              audio, // передаем текущее значение audio
                        ),
                      ).then((newAudio) {
                        if (newAudio != null) {
                          ChapterNode newNode =
                              convertChapterNodeForUpdateToChapterNode(
                                  chapterNodeForUpdate);

                          newNode.music = safeBigIntParse(newAudio);

                          updateNode(newNode).then((success) {
                            if (success) {
                              print('Узел успешно обновлен');
                              chapterNode = newNode;
                            } else {
                              print('Ошибка при обновлении узла');
                            }
                          }).catchError((e) {
                            print('Ошибка при обновлении узла: $e');
                          });

                          _loadMedia(safeBigIntParse(newAudio))
                              .then((newAudioData) {
                            setState(() {
                              chapterNodeForUpdate?.music =
                                  safeBigIntParse(newAudio);
                              audio = newAudioData;
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(
                                  () {}); // Повторный вызов для обновления UI
                            });
                          });
                        }
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
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      final events = await showSceneEditorDialog(context);

                      print("получаем events");
                      print(events);

                      if (events.isNotEmpty) {
                        chapterNodeForUpdate?.events = events;

                        ChapterNode newNode =
                            convertChapterNodeForUpdateToChapterNode(
                                chapterNodeForUpdate);

                        print(newNode);

                        print("пытаемся сохранить узел");

                        updateNode(newNode).then((success) {
                          if (success) {
                            print('Узел успешно обновлен');

                            setState(() {
                              chapterNode = newNode;
                            });
                          } else {
                            print('Ошибка при обновлении узла');
                          }
                        }).catchError((e) {
                          print('Ошибка при обновлении узла: $e');
                        });
                      }
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
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      showCommentDialog();
                    },
                    child: const Text('Комментарий'),
                  ),
                  Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide.none),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => showEndDialog(),
                    child: Text('Концовка'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.chapter.status != 1
                        ? null
                        : () async {
                            try {
                              createRequest(
                                CreateRequestRequest(
                                  requestingAdminId: widget.admin.toString(),
                                  chapterId: widget.chapter.id.toString(),
                                  type: 1,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Запрос на публикацию главы отправлен'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Ошибка при отправке запроса: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: const Text('Опубликовать'),
                  ),
                ],
              )
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<ChapterNode>>(
              future: _loadChapterNodes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorWidget(snapshot.error!);
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final nodes = snapshot.data!;
                return TreeView(
                  chapter: widget.chapter,
                  chapterNodes: nodes,
                  startNode: chapterNode!,
                  admin: widget.admin,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
