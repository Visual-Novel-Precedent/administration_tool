import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

import '../../models/media.dart';

Future<ToolMedia?> getMediaById(String id) async {
  try {
    final url = Uri.parse('http://localhost:8080/get-media-by-id');

    final request = GetMediaByIdRequest(Id: id);
    final body = jsonEncode(request.toJson());

    final response = await post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {

      final contentType = response.headers['content-type'];

      final fileData = response.bodyBytes;

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