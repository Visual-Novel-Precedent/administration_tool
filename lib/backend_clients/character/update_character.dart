import 'dart:convert';

import 'package:http/http.dart';

import '../../models/characters.dart';

Future<bool> updateCharacter(Character character) async {
  try {

    final uri = Uri.parse('http://localhost:8080/update-character');

    final body = jsonEncode({
      'id': character.id.toString(),
      'name': character.name,
      'slug': character.slug,
      'color': character.color,
      'emotions': character.emotions.map((key, value) =>
          MapEntry(key.toString(), value.toString())
      )
    });

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Ошибка обновления персонажа: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}