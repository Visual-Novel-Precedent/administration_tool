import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../backend_clients/media/create_media.dart';

class AudioUploadDialog extends StatefulWidget {
  final Uint8List? existingAudio;

  const AudioUploadDialog({
    super.key,
    this.existingAudio,
  });

  @override
  State<AudioUploadDialog> createState() => _AudioUploadDialogState();
}

class _AudioUploadDialogState extends State<AudioUploadDialog> {
  Uint8List? _audioBytes;
  String? _audioUrl;
  bool _isPlaying = false;
  double _uploadProgress = 0;
  AudioElement? _currentAudioElement;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.existingAudio != null) {
      _setupExistingAudio();
    }
  }

  void _setupExistingAudio() {
    print('Начало _setupExistingAudio');

    if (widget.existingAudio == null) {
      print('existingAudio is null');
      setState(() {
        _error = 'Аудиоданные не переданы';
      });
      return;
    }

    try {
      // Сначала проверяем данные вне setState
      _audioBytes = widget.existingAudio;

      print('Размер аудио: ${_audioBytes?.length}');

      // Объявляем mimeType снаружи условного блока
      String mimeType = 'audio/mpeg';

      if (_audioBytes!.length > 4) {
        final bytes = Uint8List.view(_audioBytes!.buffer, 0, 4);
        print('Первые 4 байта: $bytes');

        if (bytes[0] == 0xFF && bytes[1] == 0xE3) {
          mimeType = 'audio/mp3';
          print('Определен как MP3 (FF E3)');
        } else if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
          mimeType = 'audio/mp3';
          print('Определен как MP3 (ID3)');
        }

        print('Используемый MIME тип: $mimeType');
      }

      // Теперь обновляем UI
      setState(() {
        print('Выполняется setState');
        _audioUrl = Url.createObjectUrl(Blob([_audioBytes!], mimeType));
        _uploadProgress = 100;
      });

      print('_setupExistingAudio завершено успешно');
    } catch (e) {
      print('Ошибка в _setupExistingAudio: $e');
      setState(() {
        _error = 'Ошибка при настройке аудио: $e';
      });
    }
  }

  Future<void> _selectAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploadProgress = 0;
      _isPlaying = false;
      _audioUrl = null;
      _audioBytes = null;
    });

    setState(() {
      _audioBytes = file.bytes!;
      _audioUrl = Url.createObjectUrl(Blob([_audioBytes!], 'audio/mpeg'));
      _uploadProgress = 100;
    });
  }

  void _togglePlayback() {
    if (_audioUrl == null) {
      setState(() {
        _error = 'Аудиофайл не загружен';
      });
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _currentAudioElement = AudioElement();
      _currentAudioElement!.src = _audioUrl!;

      _currentAudioElement!.play().catchError((error) {
        setState(() {
          _error = 'Ошибка воспроизведения: $error';
          _isPlaying = false;
        });
        print('Ошибка воспроизведения: $error');
        _currentAudioElement?.pause();
        _currentAudioElement?.remove();
        _currentAudioElement = null;
      });

      _currentAudioElement!.onEnded.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });
    } else {
      _currentAudioElement?.pause();
      _currentAudioElement?.remove();
      _currentAudioElement = null;
    }
  }

  Future<void> _uploadAudio(Uint8List bytes, BuildContext context) async {
    try {
      final id = await MediaUploader.uploadMedia(bytes, 'audio/mpeg');
      if (id != null) {
        print("новое аудио");
        print(id);
        Navigator.of(context).pop(id); // Возвращаем только ID
      }
    } catch (e) {
      print('Ошибка при загрузке: $e');
    }
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
                              icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow),
                              onPressed: _togglePlayback,
                            ),
                            Text(_isPlaying
                                ? 'Воспроизведение...'
                                : 'Готово к воспроизведению'),
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
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
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
            ElevatedButton(
              onPressed: () {
                _uploadAudio(_audioBytes!, context);
              },
              child: const Text('Сохранить'),
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
