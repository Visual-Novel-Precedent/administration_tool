import 'dart:math';

import 'package:administration_tool/models/media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

import '../backend_clients/media/get_media.dart';
import '../models/characters.dart';

class CharacterEditor extends StatefulWidget {
  final Character character;

  const CharacterEditor({
    Key? key,
    required this.character,
  }) : super(key: key);

  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  late TextEditingController nameController;
  late TextEditingController slugController;
  late Color selectedColor;
  Map<String, Uint8List?> emotions = {
    'смех': null,
    'радость': null,
    'злость': null,
    'испуг': null,
    'спокойствие': null,
    'удивление': null,
    'грусть': null,
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.character.name);
    slugController = TextEditingController(
        text: widget.character.name.toLowerCase().replaceAll(' ', '-'));
    selectedColor = HexColor(widget.character.color);

    _initEmotions(widget.character.emotions);
  }

  @override
  void dispose() {
    nameController.dispose();
    slugController.dispose();
    super.dispose();
  }

  Future<void> _initEmotions(Map<BigInt, BigInt> emot) async {
    emot.forEach((key, value) async {
      if (key == 1) {
        try {
          emotions["1"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 2) {
        try {
          emotions["2"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 3) {
        try {
          emotions["3"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 4) {
        try {
          emotions["4"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 5) {
        try {
          emotions["5"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 6) {
        try {
          emotions["6"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      } else if (key == 7) {
        try {
          emotions["7"] = await _loadMedia(value);
        } catch (e) {
          print('Ошибка при загрузке эмоции: $e');
        }
      }
    });
  }

  Future<void> pickImage(String emotion) async {
    final Uint8List? bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes != null) {
      setState(() {
        emotions[emotion] = bytes;
      });
    }
  }

  Future<Uint8List> _loadMedia(BigInt id) async {
    try {
      final media = await getMediaById(id.toString());
      if (media != null) {
        return media.fileData;
      }
      throw Exception('Медиа не найдено');
    } catch (e) {
      print('Ошибка: $e');
      throw Exception('Ошибка при загрузке медиа: $e');
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Левая панель с вводом и выбором цвета
          Container(
            width: 300,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя персонажа',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _showColorPicker,
                  child: Text('Выбрать цвет'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                // Панель для отображения цвета
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Выбранный цвет',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Правая панель с эмоциями
          // Правая панель с эмоциями
          // Правая панель с эмоциями
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Загрузка изображений для эмоций',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 16),
                  Flexible(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        mainAxisSpacing: 4, // Уменьшили вертикальное расстояние
                        crossAxisSpacing:
                            4, // Уменьшили горизонтальное расстояние
                      ),
                      itemCount: emotions.length,
                      itemBuilder: (context, index) {
                        String emotion = emotions.keys.elementAt(index);

                        bool isLastRow = index >= emotions.length - 1;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                bottom: isLastRow ? 4 : 4,
                                // Уменьшили отступы
                                top: 4,
                                left: index % 3 == 0 ? 4 : 2,
                                // Уменьшили боковые отступы
                                right: index % 3 == 2 ? 4 : 2,
                              ),
                              child: GestureDetector(
                                onTap: () => pickImage(emotion),
                                child: Container(
                                  width: 140, // Увеличили размер квадрата
                                  height: 140,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: emotions[emotion] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.memory(
                                            emotions[emotion]!,
                                            fit: BoxFit.cover,
                                            width: 140,
                                            height: 140,
                                          ),
                                        )
                                      : Container(),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              emotion,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
