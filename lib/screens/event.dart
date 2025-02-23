import 'package:flutter/material.dart';

import 'character_position_in_node.dart';

class SceneEditor extends StatefulWidget {

  const SceneEditor({super.key});

  @override
  State<SceneEditor> createState() => _SceneEditorState();
}

class _SceneEditorState extends State<SceneEditor> {
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, dynamic>> charactersData = [];
  List<Map<String, dynamic>> availableCharacters = [];

  Future<void> showDialogToAddCharacter(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SceneCharacters()),
    );

    if (result != null) {
      setState(() {
        charactersData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Название сцены',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => showDialogToAddCharacter(context),
              child: const Text('Настройка персонажей'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: charactersData.length,
              itemBuilder: (context, index) {
                final character = charactersData[index];
                return CharacterItem(
                  character: character,
                  onDelete: () {
                    setState(() {
                      charactersData.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            charactersData.add({
              'id': DateTime.now().millisecondsSinceEpoch,
              'characterId': null,
              'text': '',
              'voiceOver': ''
            });
          });
        },
        tooltip: 'Добавить событие',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CharacterItem extends StatelessWidget {
  final Map<String, dynamic> character;
  final VoidCallback onDelete;

  const CharacterItem({
    required this.character,
    required this.onDelete,
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
                DropdownButton<String>(
                  value: character['characterId'] ?? null,
                  hint: const Text('Выберите персонажа'),
                  onChanged: (value) {
                    character['characterId'] = value;
                  },
                  items: ['Персонаж 1', 'Персонаж 2'].map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Текст',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => character['text'] = value,
            ),
          ],
        ),
      ),
    );
  }
}