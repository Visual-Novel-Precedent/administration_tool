import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:administration_tool/models/media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

import '../backend_clients/character/update_character.dart';
import '../backend_clients/media/create_media.dart';
import '../backend_clients/media/get_media.dart';
import '../models/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';


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
  bool isLoading = false;

  Map<BigInt, BigInt> newEmotions = {};

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.character.name);
    slugController = TextEditingController(
        text: widget.character.name.toLowerCase().replaceAll(' ', '-'));
    selectedColor = HexColor(widget.character.color);

    _initEmotions(widget.character.emotions);

    newEmotions = widget.character.emotions;
  }

  Future<void> saveCharacter() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Собираем данные для сохранения
      final characterData = Character(
        name: nameController.text,
        slug: slugController.text,
        color: '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}',
        emotions: newEmotions,
        id: widget.character.id,
      );

      updateCharacter(characterData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Персонаж сохранен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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

  BigInt? _getEmotionId(String emotionName) {
    switch (emotionName) {
      case 'смех':
        return BigInt.from(1);
      case 'радость':
        return BigInt.from(2);
      case 'злость':
        return BigInt.from(3);
      case 'испуг':
        return BigInt.from(4);
      case 'спокойствие':
        return BigInt.from(5);
      case 'удивление':
        return BigInt.from(6);
      case 'грусть':
        return BigInt.from(7);
      default:
        return null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    slugController.dispose();
    super.dispose();
  }

  late Future<void> uploadExisting;

  Future<void> _initEmotions(Map<BigInt, BigInt> emot) async {
    setState(() {
      isLoading = true;
    });

    try {
      for (MapEntry<BigInt, BigInt> entry in emot.entries) {
        String? emotionKey = _getEmotionKey(entry.key);
        if (emotionKey != null) {
          try {
            final bytes = await _loadMedia(entry.value);
            if (bytes != null && bytes.isNotEmpty) {
              setState(() {
                emotions[emotionKey] = bytes;
              });
            }
          } catch (e) {
            print('Ошибка при загрузке эмоции $emotionKey: $e');
          }
        }
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String? _getEmotionKey(BigInt id) {
    switch (id.toInt()) {
      case 1:
        return 'смех';
      case 2:
        return 'радость';
      case 3:
        return 'злость';
      case 4:
        return 'испуг';
      case 5:
        return 'спокойствие';
      case 6:
        return 'удивление';
      case 7:
        return 'грусть';
      default:
        return null;
    }
  }

  Future<void> pickImage(String emotion) async {
    try {
      // Просто получаем изображение как bytes
      final bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes == null) {
        print('Ошибка: изображение не получено');
        return;
      }

      // Проверяем формат PNG
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A) {
        await _uploadImage(bytes, emotion);
      } else {
        print('Неверный формат файла');
      }
    } catch (e) {
      print('Ошибка при обработке изображения: $e');
    }
  }

  Future<void> _uploadImage(Uint8List bytes, String emotion) async {
    try {
      final id = await MediaUploader.uploadMedia(bytes, 'image/png');
      if (id != null) {
        setState(() {
          var emId = _getEmotionId(emotion);
          if (emId != null) {
            emotions[emotion] = bytes;
            newEmotions[emId] = safeBigIntParse(id)!;
          }
        });
      }
    } catch (e) {
      print('Ошибка при загрузке: $e');
    }
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
                const SizedBox(
                  height: 350,
                ),
                ElevatedButton(
                  onPressed: saveCharacter,
                  child: Text('Сохранить'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Flexible(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: emotions.length,
                            itemBuilder: (context, index) {
                              String emotion = emotions.keys.elementAt(index);

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom:
                                          index >= emotions.length - 1 ? 4 : 4,
                                      top: 4,
                                      left: index % 3 == 0 ? 4 : 2,
                                      right: index % 3 == 2 ? 4 : 2,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => pickImage(emotion),
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    print(
                                                        'Ошибка при загрузке изображения: $error');
                                                    return const Icon(
                                                        Icons.error_outline);
                                                  },
                                                ),
                                              )
                                            : const Icon(Icons.image),
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
