import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:momnt/screens/camera_capture_screen.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/services/recording_cleanup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatMediaException implements Exception {
  const ChatMediaException(this.message);
  final String message;
}

/// Platform işlemleri UI'dan ayrıdır; testlerde gerçek mikrofon açılmaz.
class ChatMediaService {
  AudioRecorder? _recorder;
  final _watch = Stopwatch();
  bool _disposed = false;
  bool _recording = false;
  bool _paused = false;
  String _extension = 'm4a';
  String _mimeType = 'audio/mp4';

  Future<ChatAttachment?> takePhoto(BuildContext context) async {
    final photo = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (photo == null) return null;
    try {
      if (_disposed) return null;
      if (await photo.length() > ChatAttachment.maxBytes) {
        throw const ChatMediaException('Fotoğraf 20 MB sınırını aşıyor.');
      }
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty || bytes.length > ChatAttachment.maxBytes) {
        throw const ChatMediaException(
          'Fotoğraf okunamadı veya boyutu çok büyük.',
        );
      }
      return ChatAttachment(
        kind: ChatAttachmentKind.image,
        name: 'kamera-${DateTime.now().millisecondsSinceEpoch}.jpg',
        bytes: bytes,
        mimeType: photo.mimeType ?? 'image/jpeg',
      );
    } finally {
      await releaseRecording(photo.path);
    }
  }

  Future<ChatAttachment?> pick(ChatAttachmentKind kind) async {
    final file = await FilePicker.pickFile(
      type: kind == ChatAttachmentKind.image ? FileType.image : FileType.any,
      dialogTitle: kind == ChatAttachmentKind.image
          ? 'Fotoğraf seç'
          : 'Belge seç',
    );
    if (file == null || _disposed) return null;
    if ((await file.length() ?? 0) > ChatAttachment.maxBytes) {
      throw const ChatMediaException(
        'En fazla 20 MB boyutunda dosya seçebilirsin.',
      );
    }
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (buffer.length + chunk.length > ChatAttachment.maxBytes) {
        throw const ChatMediaException(
          'En fazla 20 MB boyutunda dosya seçebilirsin.',
        );
      }
      buffer.add(chunk);
    }
    final bytes = buffer.takeBytes();
    if (bytes.isEmpty || bytes.length > ChatAttachment.maxBytes) {
      throw const ChatMediaException('Dosya boş veya 20 MB sınırını aşıyor.');
    }
    final ext = file.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
    return ChatAttachment(
      kind: kind,
      name: file.name,
      bytes: bytes,
      mimeType: mime,
    );
  }

  Future<void> startRecording() async {
    if (_disposed) throw const ChatMediaException('Sohbet kapatıldı.');
    final recorder = _recorder ??= AudioRecorder();
    if (!await recorder.hasPermission()) {
      throw const ChatMediaException(
        'Ses kaydı için mikrofon izni vermelisin.',
      );
    }
    if (_disposed) return;
    var encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;
    if (!await recorder.isEncoderSupported(encoder)) {
      encoder = AudioEncoder.aacLc;
    }
    if (!await recorder.isEncoderSupported(encoder)) {
      throw const ChatMediaException('Bu cihazda ses kaydı desteklenmiyor.');
    }
    _extension = encoder == AudioEncoder.opus ? 'webm' : 'm4a';
    _mimeType = encoder == AudioEncoder.opus ? 'audio/webm' : 'audio/mp4';
    final name =
        'momnt-ses-${DateTime.now().microsecondsSinceEpoch}.$_extension';
    final path = kIsWeb
        ? name
        : '${(await getTemporaryDirectory()).path}/$name';
    if (_disposed) return;
    await recorder.start(RecordConfig(encoder: encoder), path: path);
    if (_disposed) {
      await recorder.cancel();
      return;
    }
    _recording = true;
    _paused = false;
    _watch
      ..reset()
      ..start();
  }

  Future<void> pauseRecording() async {
    if (!_recording || _paused || _disposed) return;
    await _recorder!.pause();
    _paused = true;
    _watch.stop();
  }

  Future<void> resumeRecording() async {
    if (!_recording || !_paused || _disposed) return;
    await _recorder!.resume();
    _paused = false;
    _watch.start();
  }

  Future<ChatAttachment?> stopRecording() async {
    if (!_recording) return null;
    _recording = false;
    _paused = false;
    _watch.stop();
    final duration = _watch.elapsed;
    final path = await _recorder!.stop();
    if (path == null) throw const ChatMediaException('Ses kaydı alınamadı.');
    try {
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty || bytes.length > ChatAttachment.maxBytes) {
        throw const ChatMediaException('Ses kaydı boş veya boyutu çok büyük.');
      }
      return ChatAttachment(
        kind: ChatAttachmentKind.audio,
        name: 'Ses kaydı.$_extension',
        bytes: bytes,
        mimeType: _mimeType,
        duration: duration,
      );
    } finally {
      await releaseRecording(path);
    }
  }

  Future<void> cancelRecording() async {
    _watch.stop();
    _recording = false;
    _paused = false;
    await _recorder?.cancel();
  }

  Future<void> dispose() async {
    _disposed = true;
    _watch.stop();
    if (_recording) await cancelRecording();
    await _recorder?.dispose();
  }
}
