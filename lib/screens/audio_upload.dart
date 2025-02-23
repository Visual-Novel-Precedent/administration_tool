import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AudioUploadDialog extends StatefulWidget {
  const AudioUploadDialog({super.key});

  @override
  State<AudioUploadDialog> createState() => _AudioUploadDialogState();
}

class _AudioUploadDialogState extends State<AudioUploadDialog> {
  Uint8List? _audioBytes;
  String? _audioUrl;
  bool _isPlaying = false;
  double _uploadProgress = 0;
  AudioElement? _currentAudioElement;  // Добавлено для хранения текущего элемента аудио

  Future<void> _selectAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        debugPrint('Пользователь отменил выбор файла');
        return;
      }

      if (result.files.isEmpty) {
        debugPrint('Нет выбранных файлов');
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        debugPrint('Нет данных файла');
        return;
      }

      setState(() {
        _uploadProgress = 0;
        _isPlaying = false;
        _audioUrl = null;
        _audioBytes = null;
      });

      final Uint8List bytes = file.bytes!;
      final blob = Blob([bytes], 'audio/mpeg');

      setState(() {
        _audioBytes = bytes;
        _audioUrl = Url.createObjectUrl(blob);
        _uploadProgress = 100;
      });

      debugPrint('Загружено ${bytes.length ~/ 1024} KB');
    } catch (e) {
      print('Ошибка при выборе аудио: $e');
      ScaffoldMessenger.of(context)?.showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _togglePlayback() {
    if (_audioUrl == null) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // Создаем новый аудио элемент для воспроизведения
      _currentAudioElement = AudioElement();
      _currentAudioElement!.src = _audioUrl!;

      _currentAudioElement!.play().catchError((_) {
        ScaffoldMessenger.of(context)?.showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения')),
        );
      });
    } else {
      // Останавливаем текущее воспроизведение
      _currentAudioElement?.pause();
      _currentAudioElement?.remove();
      _currentAudioElement = null;
    }
  }

  @override
  void dispose() {
    // Очищаем аудио элемент при закрытии диалога
    _currentAudioElement?.pause();
    _currentAudioElement?.remove();
    _currentAudioElement = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = min(screenWidth * 0.8, 500);

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
                  'Загрузка аудио',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _audioUrl != null
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: _togglePlayback,
                      ),
                      Text(_isPlaying ? 'Воспроизведение...' : 'Готово к воспроизведению'),
                    ],
                  )
                      : const Center(child: Icon(Icons.music_off)),
                  if (_uploadProgress > 0 && _uploadProgress < 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
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
              onPressed: _selectAudio,
              child: const Text('Выбрать аудио'),
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