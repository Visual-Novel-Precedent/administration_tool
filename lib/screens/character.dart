import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:administration_tool/models/media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

    String colorString = widget.character.color;

    if (colorString.startsWith('#')) {
      String hexValue = colorString.substring(1);
      if (hexValue.length == 6) {
        hexValue = 'FF$hexValue';
      }
      selectedColor = Color(int.parse('0x$hexValue'));
    } else {
      selectedColor = Colors.white;
    }

    _initEmotions(widget.character.emotions);

    newEmotions = widget.character.emotions;
  }

  String colorToHtml(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  Color htmlToColor(String htmlColor) {
    final colorStr = htmlColor.replaceFirst('#', '');
    final r = int.parse(colorStr.substring(0, 2), radix: 16);
    final g = int.parse(colorStr.substring(2, 4), radix: 16);
    final b = int.parse(colorStr.substring(4, 6), radix: 16);
    return Color.fromRGBO(r, g, b, 1.0);
  }

  Future<void> saveCharacter() async {
    try {
      setState(() {
        isLoading = true;
      });

      final characterData = Character(
        name: nameController.text,
        slug: slugController.text,
        color: colorToHtml(selectedColor),
        emotions: newEmotions,
        id: widget.character.id,
      );

      await updateCharacter(characterData);

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
      final bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes == null) {
        print('Ошибка: изображение не получено');
        return;
      }

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
                      const Text(
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
                const SizedBox(height: 350),
                ElevatedButton(
                  onPressed: saveCharacter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding:  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Загрузка изображений для эмоций',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  const SizedBox(height: 16),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Flexible(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                bottom: index >= emotions.length - 1 ? 4 : 4,
                                top: 4,
                                left: index % 3 == 0 ? 4 : 2,
                                right: index % 3 == 2 ? 4 : 2,
                              ),
                              child: GestureDetector(
                                onTap: () => pickImage(emotion),
                                child: Container(
                                  width: 140,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: emotions[emotion] != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      emotions[emotion]!,
                                      fit: BoxFit.cover,
                                      width: 88,
                                      height: 220,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Ошибка при загрузке изображения: $error');
                                        return const Icon(Icons.error_outline);
                                      },
                                    ),
                                  )
                                      : const Icon(Icons.image),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emotion,
                              style: const TextStyle(
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