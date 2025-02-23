import 'dart:convert';
import 'package:flutter/material.dart';

class SceneCharacters extends StatefulWidget {
  const SceneCharacters({super.key});

  @override
  State<SceneCharacters> createState() => _SceneCharactersState();
}

class _SceneCharactersState extends State<SceneCharacters> {
  final List<String> emotions = [
    'смех',
    'радость',
    'злость',
    'испуг',
    'спокойствие',
    'удивление',
    'грусть'
  ];

  Map<String, dynamic> charactersData = {
    "characters": [
      {
        "name": "Юля",
        "position": 0,
        "emotions": ["радость"],
      },
      {
        "name": "Даня",
        "position": 0,
        "emotions": ["спокойствие"],
      },
      {
        "name": "Эви",
        "position": 0,
        "emotions": ["смех"],
      },
      {
        "name": "Павел",
        "position": 0,
        "emotions": ["злость"],
      }
    ]
  };

  List<Map<String, dynamic>> availableCharacters = [
    {"name": "Настя", "position": 0},
    {"name": "Жора", "position": 0},
    {"name": "Сергей", "position": 0},
    {"name": "Даша", "position": 0},
  ];

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
                      charactersData['characters'].add(
                          Map<String, Object>.fromEntries(character.entries.map(
                                  (entry) => MapEntry<String, Object>(
                                  entry.key, entry.value))));
                      availableCharacters.removeAt(index);
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
              itemCount: charactersData['characters'].length,
              itemBuilder: (context, index) {
                final character = charactersData['characters'][index] as Map<String, dynamic>;
                return CharacterCard(
                  character: character,
                  emotions: emotions,
                  onEmotionChange: (String newEmotion) {
                    setState(() {
                      character['emotions'] = [newEmotion];
                    });
                  },
                  onPositionChange: (double newPosition) {
                    setState(() {
                      character['position'] = newPosition;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      charactersData['characters'].removeAt(index);
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

class CharacterCard extends StatelessWidget {
  final Map<String, dynamic> character;
  final List<String> emotions;
  final void Function(String) onEmotionChange;
  final void Function(double) onPositionChange;
  final void Function() onDelete;

  const CharacterCard({
    super.key,
    required this.character,
    required this.emotions,
    required this.onEmotionChange,
    required this.onPositionChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String currentEmotion = character['emotions'] == null || character['emotions'].isEmpty
        ? emotions[0]
        : character['emotions'].first as String;

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
                    character['name'] as String,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButton<String>(
                    value: currentEmotion,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        onEmotionChange(newValue);
                      }
                    },
                    items: emotions.map((emotion) {
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
                          value: character['position'].toDouble(),
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          onChanged: onPositionChange,
                        ),
                      ),
                      Text('${character['position'].toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
