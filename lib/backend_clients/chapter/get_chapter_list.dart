import 'package:http/http.dart';

import '../../models/chapter.dart';
import 'dart:convert';

class GetChaptersByUserIdRequest {
  final BigInt userId;

  GetChaptersByUserIdRequest({required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId.toString(),
    };
  }
}

class ChaptersResponse {
  final List<Chapter> chapters;

  ChaptersResponse({required this.chapters});

  factory ChaptersResponse.fromJson(Map<String, dynamic> json) {
    List<Chapter> chaptersList = [];

    if (json['chapters'] != null) {
      json['chapters'].forEach((chapterJson) {
        chaptersList.add(Chapter.fromJson(chapterJson));
      });
    }

    print("res");
    print(chaptersList);

    return ChaptersResponse(chapters: chaptersList);
  }
}

Future<List<Chapter>> getChaptersByUserId(BigInt userId) async {
  try {
    final uri = Uri.parse('http://localhost:8080/get-chapters');

    print(userId);

    final requestBody = {
      'user_id': userId.toString(),
    };

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final ChaptersResponse chaptersResponse = ChaptersResponse.fromJson(jsonDecode(response.body));
      print("парс прошел успешно");
      print(chaptersResponse.chapters.length);
      return chaptersResponse.chapters;
    } else {
      throw Exception('Ошибка при получении глав: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}