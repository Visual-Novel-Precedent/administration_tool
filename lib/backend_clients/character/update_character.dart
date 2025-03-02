import 'dart:convert';

import 'package:http/http.dart';

import '../../models/characters.dart';

Future<bool> updateCharacter(Character character) async {
  try {
    print('1. Начало отправки запроса');
    print('2. Данные для отправки: ${jsonEncode(character)}');

    final uri = Uri.parse('http://localhost:8080/update-character');
    print('3. URI: $uri');

    final body = jsonEncode({
      'id': character.id.toString(),
      'name': character.name,
      'slug': character.slug,
      'color': character.color,
      'emotions': character.emotions.map((key, value) =>
          MapEntry(key.toString(), value.toString())
      )
    });
    print('4. Преобразованные данные: $body');

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );
    print('5. Получен ответ со статусом: ${response.statusCode}');
    print('6. Тело ответа: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Ошибка обновления персонажа: ${response.statusCode}');
    }
  } catch (e) {
    print('7. Тип ошибки: ${e.runtimeType}');
    print('8. Сообщение ошибки: $e');
    rethrow;
  }
}