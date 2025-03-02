import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

import '../../models/media.dart';

Future<ToolMedia?> getMediaById(String id) async {
  try {
    // Создаем URL для запроса
    final url = Uri.parse('http://localhost:8080/get-media-by-id');

    // Подготавливаем данные для запроса
    final request = GetMediaByIdRequest(Id: id);
    final body = jsonEncode(request.toJson());

    // Отправляем POST-запрос
    final response = await post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    // Проверяем статус ответа
    if (response.statusCode == 200) {
      // Извлекаем контент-тип из заголовков
      final contentType = response.headers['content-type'];

      // Читаем данные файла используя bodyBytes вместо bytes
      final fileData = response.bodyBytes;

      // Возвращаем объект ToolMedia
      return ToolMedia(
        contentType: contentType ?? '',
        fileData: fileData,
      );
    } else {
      print('Ошибка при получении медиафайла: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Ошибка при выполнении запроса: $e');
    return null;
  }
}

class GetMediaByIdRequest {
  final String Id;

  GetMediaByIdRequest({
    required this.Id,
  });

  // Преобразование в JSON
  Map<String, dynamic> toJson() => {
    'id': Id,
  };
}