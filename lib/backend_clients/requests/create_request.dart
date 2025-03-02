// Модель данных для отправки
import 'dart:convert';

import 'package:http/http.dart';

class CreateRequestRequest {
  final String requestingAdminId;
  final String? chapterId;
  final int type;

  CreateRequestRequest({
    required this.requestingAdminId,
    this.chapterId,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'requesting_admin_id': requestingAdminId,
      'chapter_id': chapterId,
      'type': type,
    };
  }
}

void createRequest(CreateRequestRequest request) async {
  try {
    final uri = Uri.parse('http://localhost:8080/create-request'); // замените на нужный URL

    final response = await post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("запрос успешно отправлен");
    } else {
      throw Exception('Ошибка при создании заявки: ${response.statusCode}');
    }
  } catch (e) {
    print('Тип ошибки: ${e.runtimeType}');
    print('Сообщение ошибки: $e');
    rethrow;
  }
}