import 'dart:convert';

import 'package:http/http.dart';

import '../../models/chapter.dart';

class CreateChapterRequest {
  final String author;

  CreateChapterRequest({
    required this.author,
  });

  Map<String, dynamic> toJson() {
    return {
      'author': author,
    };
  }
}

Future<Chapter> createChapter(CreateChapterRequest request) async {
  print("Запрос на создание главы");
  print(request);

  try {
    final uri = Uri.parse('http://localhost:8080/create-chapter');

    final requestBody = request.toJson();

    print('До вызова функции');
    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      return Chapter(
        id: BigInt.parse(responseBody['id'] ?? '0'),
        name: 'Новая глава',
        startNode: BigInt.parse(responseBody['start_node'] ?? '0'),
        nodes: [],
        characters: [],
        status: 0,
        author: BigInt.parse(request.author),
      );
    } else {
      throw Exception('Ошибка при создании главы: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}