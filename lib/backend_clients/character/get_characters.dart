import 'dart:convert';

import 'package:http/http.dart';

import '../../models/characters.dart';

class CharacterResponse {
  final List<Character> character;

  CharacterResponse({required this.character});

  factory CharacterResponse.fromJson(Map<String, dynamic> json) {
    List<Character> characterList = [];

    if (json['characters'] != null) {
      json['characters'].forEach((characterJson) {
        characterList.add(Character.fromJson(characterJson));
      });
    }

    return CharacterResponse(character: characterList);
  }
}

Future<List<Character>> getCharactersByUserId() async {
  try {
    final uri = Uri.parse('http://localhost:8080/get-characters');

    final response = await get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      print(response.body);
      final CharacterResponse chaptersResponse = CharacterResponse.fromJson(jsonDecode(response.body));
      return chaptersResponse.character;
    } else {
      throw Exception('Ошибка при получении глав: ${response.statusCode}');
    }
  } catch (e) {
    print("ошибка точно тут");
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}