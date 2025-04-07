import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/services.dart';

import '../backend_clients/media/create_media.dart';
import '../backend_clients/media/get_media.dart';
import '../models/node.dart';

import 'package:flutter/material.dart';

import '../models/characters.dart';
import 'audio_upload.dart';
import 'character_position_in_node.dart';

class CharacterItem extends StatelessWidget {
  final Map<String, dynamic> character;
  final VoidCallback onDelete;
  final VoidCallback onConfigureCharacter;
  final List<Map<BigInt, String>> selectedCharacters;
  final VoidCallback onMusicClick;
  final Function(String) onTextChange;
  final Function(String)
      onCharacterChange; // Новый callback для обновления персонажа

  const CharacterItem({
    required this.character,
    required this.onDelete,
    required this.onConfigureCharacter,
    required this.selectedCharacters,
    required this.onMusicClick,
    required this.onTextChange,
    required this.onCharacterChange, // Обязательный параметр
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: character['characterId'] ?? '0', // Используем '0' как дефолтное значение
                    hint: const Text('Выберите персонажа'),
                    onChanged: (value) {
                      character['characterId'] = value;
                      onCharacterChange(value ?? '');
                    },
                    items: selectedCharacters.map((char) {
                      return DropdownMenuItem(
                        value: char.keys.first.toString(),
                        child: Text(char.values.first),
                      );
                    }).toList(),
                  )
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_outline),
                      onPressed: onConfigureCharacter,
                    ),
                    IconButton(
                      icon: const Icon(Icons.music_note_outlined),
                      onPressed: onMusicClick,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: character['text'],
              ),
              initialValue: character['text'], // Используем initialValue вместо hintText
              onChanged: onTextChange, // Прямой вызов callback
            ),
          ],
        ),
      ),
    );
  }
}

class EventForUpdate {
  BigInt type;
  BigInt character;
  BigInt sound;
  Map<BigInt, Map<BigInt, BigInt>> charactersInEvent;
  String text;

  EventForUpdate({
    required this.type,
    required this.character,
    required this.sound,
    required this.charactersInEvent,
    required this.text,
  });

  Event toEvent() {
    return Event(
      type: type,
      character: character,
      sound: sound,
      charactersInEvent: charactersInEvent,
      text: text,
    );
  }

  @override
  String toString() {
    return 'Event(type: $type, character: $character, sound: $sound, '
        'charactersInEvent: $charactersInEvent, text: $text)';
  }
}

class SceneEditor extends StatefulWidget {
  final List<Character> characters;
  final Map<int, Event> events;

  const SceneEditor(
      {super.key, required this.characters, required this.events});

  @override
  State<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<SceneEditor> {
  final TextEditingController _titleController = TextEditingController();
  List<Map<BigInt, String>> selectedCharacters = [];

  List<Character> characters = [];
  Map<int, Event> events = {};

  Map<int, EventForUpdate> eventForUpdate = {};

  Uint8List? audio;

  @override
  void initState() {
    characters = widget.characters;
    events = widget.events;

    print("на экране event проверка");
    print(characters);
    print(events);

    eventForUpdate = convertEventsToEventForUpdate(events);

    initSelectedCharacters();
  }

  Map<int, EventForUpdate> convertEventsToEventForUpdate(
      Map<int, Event> events) {
    return {
      for (var entry in events.entries)
        entry.key: EventForUpdate(
          type: entry.value.type,
          character: entry.value.character,
          sound: entry.value.sound,
          charactersInEvent: entry.value.charactersInEvent,
          text: entry.value.text,
        )
    };
  }

  void initSelectedCharacters() {
    setState(() {
      selectedCharacters.clear();
      selectedCharacters.add({BigInt.zero: 'Без персонажа'});

      final seenIds = <BigInt>{};
      eventForUpdate.forEach((key, value) {
        value.charactersInEvent.forEach((charId, value) {
          characters.forEach((element) {
            if (element.id == charId && !seenIds.contains(element.id)) {
              seenIds.add(element.id);
              selectedCharacters.add({element.id: element.name});
            }
          });
        });
      });
    });

    eventForUpdate.forEach((key, value) {
      if (value.character != BigInt.zero) {
        bool characterStillExists = selectedCharacters.any((char) =>
        char.keys.first == value.character
        );

        if (!characterStillExists) {
          value.character = BigInt.zero;
        }
      }
    });

    print("initSelectedCharacters");
    print(selectedCharacters);
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

  Future<void> showDialogToAddCharacter(
      BuildContext context, EventForUpdate event) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SceneCharacters(
            characters: characters,
            events: event,
          ),
        ));

    if (result != null) {
      setState(() {
        event = result;

        print("добавиль персонажей");
        print(event);

        initSelectedCharacters();
      });
    }
  }

  void updateText(String newText, EventForUpdate event) {
    setState(() {
      event.text = newText;
    });
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

  Future<void> _initializeAudio(EventForUpdate event) async {
    try {
      audio = await _loadMedia(event.sound);
      setState(() {}); // Обновляем UI после загрузки
    } catch (e) {
      print('Ошибка при загрузке фона: $e');
      rethrow;
    }
  }

  void _handleBackButton() async {
    try {
      print("Попытка возврата на предыдущий экран");

      print(eventForUpdate);

      if (!Navigator.canPop(context)) {
        print("Невозможно вернуться назад: это первый экран");
        return;
      }

      Map<int, Event> newEvent = {};

      eventForUpdate.forEach((key, value) {
        BigInt type = BigInt.from(0);
        if (value.character != BigInt.from(0)) {
          type = BigInt.from(3);
        }

        Map<BigInt, Map<BigInt, BigInt>> newCh = {};

        value.charactersInEvent.forEach((id, emPos) {
          Map<BigInt, BigInt> emmm = {};
          emPos.forEach((key, value) {
            emmm[key] = value;
          });

          newCh[id] = emmm;
        });

        newEvent[key] = Event(
          type: type,
          character: value.character,
          sound: value.sound,
          charactersInEvent: newCh,
          text: value.text ?? '',
        );
      });

      print("Подготовлены данные для возврата:");
      print(newEvent);

      // Используем await для получения результата
      bool result = await Navigator.maybePop(context, newEvent);

      if (result == null || !result) {
        print("Ошибка при возврате на предыдущий экран");
        // Попытка через SystemNavigator
        SystemNavigator.pop();
      } else {
        print("Успешный возврат на предыдущий экран");
      }
    } catch (e) {
      print('Ошибка при обработке возврата: $e');
      SystemNavigator.pop();
    }
  }

  void updateEventText(int index, String newText) {
    setState(() {
      if (eventForUpdate.containsKey(index)) {
        eventForUpdate[index]!.text = newText;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _handleBackButton();
          },
        ),
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: eventForUpdate.length,
        itemBuilder: (context, index) {
          final EventForUpdate event = eventForUpdate[index]!;

          return CharacterItem(
            character: {
              'id': index,
              'characterId': event.character.toString(),
              'text': event.text ?? '',
              'voiceOver': ''
            },
            onDelete: () {
              setState(() {
                eventForUpdate.remove(index);
              });
            },
            onConfigureCharacter: () =>
                showDialogToAddCharacter(context, event),
            selectedCharacters: selectedCharacters,
            onMusicClick: () async {
              print('Нажата кнопка музыки');
              print('Контекст: $context');
              print('Событие: $index');
              print('Звук: ${eventForUpdate[index]?.sound}');


              _initializeAudio(event);
              try {
                final newAudio = await showDialog<String>(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) => AudioUploadDialog(
                      existingAudio: audio,
                    ),
                  ),
                );

                if (newAudio != null) {
                  final newAudioData = await _loadMedia(safeBigIntParse(newAudio));
                  setState(() {
                    eventForUpdate[index]!.sound = safeBigIntParse(newAudio);
                    audio = newAudioData;
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {});
                  });
                }
              } catch (e) {
                print('Ошибка при загрузке аудио: $e');
              }
            },
            onTextChange: (text) => updateText(text, eventForUpdate[index]!),
            onCharacterChange: (value) {
              setState(() {
                print("смена персонажа");
                print(value);
                eventForUpdate[index]!.character = safeBigIntParse(value);
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            eventForUpdate[eventForUpdate.length] = EventForUpdate(
              type: BigInt.zero,
              character: BigInt.zero,
              sound: BigInt.zero,
              charactersInEvent: {},
              text: '',
            );
          });
        },
        tooltip: 'Добавить событие',
        child: const Icon(Icons.add),
      ),
    );
  }
}
