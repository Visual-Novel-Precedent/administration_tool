import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

class MediaUploader {
  static Future<String?> uploadMedia(
      Uint8List fileData, String contentType) async {
    try {
      final url = Uri.parse('http://localhost:8080/create-media');

      var request = MultipartRequest('POST', url);
      request.headers['Content-Type'] = 'image/png';

      request.files.add(MultipartFile.fromBytes('file', fileData,
          filename: 'media.${contentType.split('/')[1]}',
          contentType: MediaType.parse(contentType)));

      final response = await request.send();

      print("media answer");
      print(response.statusCode);
      final responseBody = await response.stream.bytesToString();
      print("media answer");
      print(responseBody);
      final jsonData = jsonDecode(responseBody);
      print("media id");
      print(jsonData['id']);
      return jsonData['id'];
    } catch (e) {
      print('Ошибка при загрузке медиафайла: $e');
      return null;
    }
  }
}
