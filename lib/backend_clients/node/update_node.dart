import 'dart:convert';

import 'package:http/http.dart';

import '../../models/node.dart';

Future<bool> updateNode(ChapterNode node) async {
  print("запрос на сохранение узла");
  try {
    final url = Uri.parse('http://localhost:8080/update-node');
    final requestBody = {
      'Id': node.id.toString(),
      'Slug': node.slug,
      'Events': node.events.map((key, value) => MapEntry(key.toString(), value.toJson())),
      'Music': node.music.toString(),
      'Background': node.background.toString(),
      'Branching': {
        'Flag': node.branching.flag,
        'Condition': node.branching.condition.map((key, value) => MapEntry(key, value.toString()))
      },
      'End': {
        'Flag': node.end.flag,
        'EndResult': node.end.endResult,
        'EndText': node.end.endText
      },
      'Comment': node.comment
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    print("боди для запроса на изменение узла");
    print(jsonEncode(requestBody));

    final response = await post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Ошибка при выполнении запроса: $e');
    return false;
  }
}