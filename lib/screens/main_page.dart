import 'package:administration_tool/screens/character.dart';
import 'package:flutter/material.dart';

import 'authorization.dart';


class Request {
  final int id;
  final String from;
  final int type;
  final String? chapter;

  Request({
    required this.id,
    required this.from,
    required this.type,
    this.chapter,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      from: json['from'],
      type: json['type'],
      chapter: json['chapter'],
    );
  }

  String getDescription() {
    switch (type) {
      case 0:
        return 'Запрос на получение статуса суперадмина';
      case 1:
        return 'Запрос на публикацию главы $chapter';
      case 2:
        return 'Запрос на регистрацию';
      default:
        return 'Неизвестный тип запроса';
    }
  }
}

// // Класс для представления персонажа
class Character {
  final int id;
  final String name;

  Character(this.id, this.name);
}

// Главный экран приложения
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Состояние для отслеживания выбранной опции в левой панели
  String selectedOption = 'chapters';

  // Данные для глав, запросов и персонажей
  final List<Map<String, dynamic>> chapters = [
    {'id': 1, 'title': 'Глава 1'},
    {'id': 2, 'title': 'Глава 2'},
    {'id': 3, 'title': 'Глава 3'},
    {'id': 4, 'title': 'Глава 4'},
  ];

  List<Request> requests = [
    Request(id: 5678, from: 'Александра', type: 0),
    Request(id: 5678, from: 'Женя', type: 1, chapter: 'chapter 1'),
    Request(id: 56789, from: 'Костя', type: 2),
  ];

  final List<Map<String, dynamic>> characters = [
    {'id': 1, 'name': 'Персонаж 1'},
    {'id': 2, 'name': 'Персонаж 2'},
    {'id': 3, 'name': 'Персонаж 3'},
    {'id': 4, 'name': 'Персонаж 4'},
  ];

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'ИМЯ ПОЛЬЗОВАТЕЛЯ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                        onPressed: () => setState(() => selectedOption = 'requests'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Запросы'),
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
                          MaterialPageRoute(builder: (context) => const LoginPage()),
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
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
                  const SizedBox(height: 20),

                  // Обновленный ListView.builder для всех типов контента
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedOption == 'chapters'
                          ? chapters.length
                          : selectedOption == 'requests'
                          ? requests.length
                          : characters.length,
                      itemBuilder: (context, index) {
                        if (selectedOption == 'requests') {
                          // Новый виджет для отображения запросов
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ExpansionTile(
                              title: Text('Запрос от ${requests[index].from}'),
                              children: [
                                ListTile(
                                  title: Text(requests[index].getDescription()),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed: () async {
                                          final bool? confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Подтверждение'),
                                              content: const Text('Вы уверены что хотите одобрить запрос?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Отмена'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Подтвердить'),
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
                                          final bool? confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Подтверждение'),
                                              content: const Text('Вы уверены что хотите отказать в запросе?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Отмена'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Подтвердить'),
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
                          );
                        } else {
                          // Старый код для глав и персонажей остается без изменений
                          final item = selectedOption == 'chapters'
                              ? chapters[index]
                              : characters[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListTile(
                                title: Text(item['title'] ?? item['name']),
                                trailing: selectedOption == 'chapters'
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        // Добавьте логику удаления
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        // Добавьте логику редактирования
                                      },
                                    ),
                                  ],
                                )
                                    : selectedOption == 'requests'
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () {
                                        // Добавьте логику подтверждения
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        // Добавьте логику отклонения
                                      },
                                    ),
                                  ],
                                )
                                    : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        // Добавьте логику удаления
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        // Добавьте логику редактирования
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
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

