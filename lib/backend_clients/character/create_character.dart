import 'dart:convert';

import 'package:http/http.dart';

Future<String?> createCharacter(String name, String slug) async {
  try {
    print('1. Начало создания персонажа');

    final uri = Uri.parse('http://localhost:8080/create-character');
    print('2. URI: $uri');

    final body = jsonEncode({
      'name': name,
      'slug': slug,
    });
    print('3. Преобразованные данные: $body');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    print('4. Получен ответ со статусом: ${response.statusCode}');
    print('5. Тело ответа: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      return responseBody['id'];
    } else {
      throw Exception('Ошибка создания персонажа: ${response.statusCode}');
    }
  } catch (e) {
    print('6. Тип ошибки: ${e.runtimeType}');
    print('7. Сообщение ошибки: $e');
    rethrow;
  }
}