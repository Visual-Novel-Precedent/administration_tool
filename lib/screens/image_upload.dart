import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDialog extends StatefulWidget {
  const ImageUploadDialog({super.key});

  @override
  State<ImageUploadDialog> createState() => _ImageUploadDialogState();
}

class _ImageUploadDialogState extends State<ImageUploadDialog> {
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  double _uploadProgress = 0;

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
      );

      if (image != null) {
        setState(() {
          _uploadProgress = 0;
        });

        int totalBytes = await image.length();
        int bytesRead = 0;

        final stream = image.openRead();
        final bytesBuilder = BytesBuilder();

        await for (final chunk in stream.map((chunkData) {
          bytesBuilder.add(chunkData);
          bytesRead += chunkData.length;

          if ((bytesRead / totalBytes * 100 - _uploadProgress).abs() > 1) {
            setState(() {
              _uploadProgress = (bytesRead / totalBytes * 100).clamp(0, 100);
            });
          }

          return chunkData;
        }));

        final Uint8List bytes = bytesBuilder.toBytes();

        setState(() {
          _selectedImageBytes = bytes;
          _uploadProgress = 100;
        });

        debugPrint('Загружено ${bytes.length ~/ 1024} KB');
      }
    } catch (e) {
      print('Ошибка при выборе изображения: $e');
      ScaffoldMessenger.of(context)?.showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = min(screenWidth * 0.8, 500);
    final double imageSize = dialogWidth * 0.8;

    return Dialog(
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Загрузка изображения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  _selectedImageBytes != null
                      ? Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Ошибка загрузки изображения: $error');
                      return const Center(child: Icon(Icons.error));
                    },
                  )
                      : const Center(child: Icon(Icons.image_outlined)),
                  if (_uploadProgress > 0 && _uploadProgress < 100)
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _uploadProgress / 100,
                            strokeWidth: 4,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_uploadProgress.toInt()}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectImage,
              child: const Text('Выбрать изображение'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}