import 'dart:convert';

import 'package:http/http.dart';

import '../../models/node.dart';

Future<bool> updateNode(ChapterNode node) async {
  print("запрос на сохранение узла");
  print(node);
  try {
    final url = Uri.parse('http://localhost:8080/update-node');
    final requestBody = {
      'id': node.id.toString(),
      'slug': node.slug,
      'events': node.events.map((key, value) => MapEntry(key.toString(), value.toJson())),
      'music': node.music.toString(),
      'background': node.background.toString(),
      'branching': {
        'Flag': node.branching.flag,
        'Condition': node.branching.condition.map((key, value) => MapEntry(key, value.toString()))
      },
      'end': {
        'end_flag': node.end.flag,
        'end_result': node.end.endResult,
        'end_text': node.end.endText
      },
      'comment': node.comment
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

    print("response.statusCode");
    print(response.statusCode);

    return response.statusCode == 200;
  } catch (e) {
    print('Ошибка при выполнении запроса: $e');
    return false;
  }
}