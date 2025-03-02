import 'package:administration_tool/screens/tree.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'audio_upload.dart';
import 'character_position_in_node.dart';
import 'event.dart';
import 'image_upload.dart';

class ChapterScreen extends StatefulWidget {
  final String chapterTitle;
  const ChapterScreen({super.key, required this.chapterTitle});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
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
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
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
                    ),
                    onPressed: () {},
                    child: const Text('Комментарий'),
                  ),
                ],
              )
            ]),
          ),
          Expanded(
            child: TreeView(),
          ),
        ],
      ),
    );
  }
}