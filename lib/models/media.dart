import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

class ToolMedia {
  final String contentType;
  final Uint8List fileData;

  ToolMedia({
    required this.contentType,
    required this.fileData,
  });
}
