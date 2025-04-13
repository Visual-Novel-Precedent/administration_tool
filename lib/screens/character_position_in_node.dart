import 'dart:convert';
import 'package:administration_tool/screens/event.dart';
import 'package:flutter/material.dart';

import '../models/characters.dart';
import '../models/node.dart';

class SceneCharacters extends StatefulWidget {
  final List<Character> characters;
  final EventForUpdate events;

  const SceneCharacters(
      {super.key, required this.characters, required this.events});

  @override
  State<SceneCharacters> createState() => _SceneCharactersState();
}

class _SceneCharactersState extends State<SceneCharacters> {
  List<Character> characters = [];
  EventForUpdate? event;

  List<Map<String, dynamic>>  charactersData = [];

  List<Map<String, dynamic>> availableCharacters = [];

  @override
  void initState() {
    event = widget.events;
    characters = widget.characters;

    print("попали такие персонажи и сцены");
    print(event);
    print(characters);

    initCharactersData();
    initAvailableData();
  }

  final List<String> emotions = [
    'смех',
    'радость',
    'злость',
    'испуг',
    'спокойствие',
    'удивление',
    'грусть'
  ];

  void initCharactersData() {
    event?.charactersInEvent.forEach((id, posEm) {
      String? name;
      BigInt? pos;
      String? emotion;

      characters.forEach((ch) {
        if (ch.id == id) {
          name = ch.name;

          posEm.forEach((em, position) {
            pos = position;
            emotion = emotions[em.toInt() - 1];
          });
        }
      });

      if (name != null && pos != null && emotion != null) {
        charactersData.add({
          "id": id,
          "name": name,
          "position": pos,
          "emotions": [emotion],
        });
      }
    });

    print("инициализировли список персонажей для отображения ");
    print(charactersData);
  }

  void initAvailableData() {
    characters.forEach((ch) {
      bool flag = false;

      event?.charactersInEvent.forEach((id, posEm) {
        if (ch.id == id) {
          flag = true;
        }
      });

      if (!flag) {
        availableCharacters.add({"name": ch.name, "position": 0, "id": ch.id});
      }
    });

    print("инициализировли список оставшихся персонажей ");
    print(availableCharacters);
  }

  void showDialogToAddCharacter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите персонажа'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableCharacters.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> character =
                    availableCharacters[index];
                return ListTile(
                  title: Text(character['name'] as String),
                  onTap: () {
                    setState(() {
                      // Добавляем нового персонажа с начальными значениями
                      Map<String, dynamic> newCharacter = {
                        "id": character['id'],
                        "name": character['name'],
                        "position": BigInt.from(0), // Начальная позиция
                        "emotions": [emotions[0]], // Начальная эмоция
                      };

                      charactersData.add(newCharacter);
                      availableCharacters.removeAt(index);

                      // Обновляем event.charactersInEvent
                      event?.charactersInEvent[character['id']] = {
                        BigInt.from(1): BigInt.from(0)
                      };

                      print('Добавлен новый персонаж:');
                      print('charactersData: $charactersData');
                      print('event: ${event?.charactersInEvent}');
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Персонажи в сцене'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print("Возвращаемся со страницы редактирования персонажей");
            print(event);
            print(event?.charactersInEvent);
            Navigator.pop(context, event);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => showDialogToAddCharacter(context),
              child: const Text('Добавить персонажа'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: charactersData.length,
              itemBuilder: (context, index) {
                final character = charactersData[index];
                return CharacterCard(
                  character: character,
                  emotions: emotions,
                  onEmotionChange: (String newEmotion) {
                    print("новая эмоция");
                    print(newEmotion);
                    setState(() {
                      final index = charactersData.indexWhere((char) => char['id'] == character['id']);
                      if (index != -1) {
                        charactersData[index]['emotion'] = newEmotion;
                        print('Обновлено в charactersData: ${charactersData[index]['emotion']}');

                        final emotionIndex = emotions.indexOf(newEmotion);
                        if (emotionIndex == -1) {
                          print('Эмоция не найдена в списке!');
                          return;
                        }

                        // Преобразуем в BigInt напрямую из индекса
                        BigInt emotionBigInt = BigInt.from(emotionIndex + 1);

                        // Получаем текущую позицию как BigInt
                        BigInt positionBigInt = BigInt.from(charactersData[index]['position'].toInt());

                        event?.charactersInEvent[character['id']] = {
                          emotionBigInt: positionBigInt
                        };

                        print('event?.charactersInEvent[character["id"]]: ${event?.charactersInEvent[character["id"]]}');
                      }
                    });
                  },
                  onPositionChange: (double newPosition) {
                    setState(() {
                      character['position'] = newPosition;

                      BigInt emotionIndex = BigInt.from(
                          emotions.indexOf(character['emotions'].first));
                      if (emotionIndex == BigInt.zero) {
                        character['emotion'] = BigInt.from(1);
                      }

                      event?.charactersInEvent[character['id']] = {
                        emotionIndex: BigInt.from(newPosition)
                      };

                      print('Обновлена позиция:');
                      print('character: ${character['position']}');
                      print(
                          'event: ${event?.charactersInEvent[character['id']]}');
                    });
                  },
                  onDelete: () {
                    setState(() {
                      event?.charactersInEvent.remove(character["id"]);
                      availableCharacters.add(charactersData[index]);
                      charactersData.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterCard extends StatefulWidget {
  final Map<String, dynamic> character;
  final List<String> emotions;
  final Function(String) onEmotionChange;
  final Function(double) onPositionChange;
  final Function() onDelete;

  const CharacterCard({
    super.key,
    required this.character,
    required this.emotions,
    required this.onEmotionChange,
    required this.onPositionChange,
    required this.onDelete,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  String _selectedEmotion = '';

  @override
  void initState() {
    super.initState();
    _selectedEmotion = widget.character['emotions']?.first as String;
  }

  @override
  Widget build(BuildContext context) {
    String currentEmotion = widget.character['emotions']?.first as String;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character['name'] as String,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButton<String>(
                    value: _selectedEmotion, // Используем локальную переменную
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedEmotion = newValue;
                          widget.onEmotionChange(newValue);
                        });
                      }
                    },
                    items: widget.emotions.map((emotion) {
                      return DropdownMenuItem(
                        value: emotion,
                        child: Text(emotion),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Text('Позиция: '),
                      Expanded(
                        child: Slider(
                          value: widget.character['position'].toDouble(),
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          onChanged: widget.onPositionChange,
                        ),
                      ),
                      Text('${widget.character['position'].toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
