import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/models/chat_attachment.dart';

String attachmentDuration(Duration duration) =>
    '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

class ChatAttachmentView extends StatefulWidget {
  const ChatAttachmentView({
    super.key,
    required this.attachment,
    this.isMine = false,
    this.isDraft = false,
    this.onOpenOnce,
  });
  final ChatAttachment attachment;
  final bool isMine;
  final bool isDraft;
  final ChatAttachment? Function()? onOpenOnce;

  @override
  State<ChatAttachmentView> createState() => _ChatAttachmentViewState();
}

class _ChatAttachmentViewState extends State<ChatAttachmentView> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _state;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  Color get _color => widget.isMine ? Colors.white : MomntColors.accent;

  @override
  void dispose() {
    unawaited(_state?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  void _error(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _play() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_player == null) {
        final player = _player = AudioPlayer();
        _state = player.onPlayerStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _playing = state == PlayerState.playing;
              if (state == PlayerState.completed) _position = Duration.zero;
            });
          }
        });
        _positionSubscription = player.onPositionChanged.listen((position) {
          if (mounted) setState(() => _position = position);
        });
      }
      if (_playing) {
        await _player!.pause();
      } else if (_player!.state == PlayerState.paused) {
        await _player!.resume();
      } else {
        await _player!.play(
          BytesSource(
            widget.attachment.bytes,
            mimeType: widget.attachment.mimeType,
          ),
        );
      }
    } catch (_) {
      _error('Ses kaydı oynatılamadı.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (widget.attachment.isViewOnce && !widget.isDraft) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FilePicker.saveFile(
        fileName: widget.attachment.name,
        bytes: widget.attachment.bytes,
        mimeType: widget.attachment.mimeType,
      );
    } catch (_) {
      _error('Dosya kaydedilemedi. Lütfen yeniden dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openOnce() async {
    if (_busy || widget.isMine || widget.attachment.openedAt != null) return;
    setState(() => _busy = true);
    ChatAttachment? photo;
    try {
      photo = widget.onOpenOnce?.call();
      if (photo == null || !mounted) return;
      final payload = photo;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Tek seferlik fotoğraf'),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(
                    payload.bytes,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Fotoğraf açılamadı.'),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (photo != null) await MemoryImage(photo.bytes).evict();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    if (attachment.kind == ChatAttachmentKind.image) {
      if (attachment.isViewOnce && !widget.isDraft) {
        final opened = attachment.openedAt != null;
        return SizedBox(
          width: 220,
          child: TextButton(
            onPressed:
                _busy || widget.isMine || opened || widget.onOpenOnce == null
                ? null
                : _openOnce,
            child: Row(
              children: [
                Icon(
                  opened
                      ? Icons.check_circle_outline
                      : Icons.looks_one_outlined,
                  color: _color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opened ? 'Fotoğraf açıldı' : 'Tek seferlik fotoğraf',
                        style: TextStyle(color: _color),
                      ),
                      Text(
                        opened
                            ? 'Tekrar açılamaz'
                            : widget.isMine
                            ? 'Gönderen tekrar açamaz'
                            : 'Bir kez açmak için dokun',
                        style: TextStyle(fontSize: 11, color: _color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      const thumbnailWidth = 220.0;
      return InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(
                      attachment.bytes,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Bu fotoğraf önizlenemiyor. Dosyayı kaydedebilirsin.',
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!attachment.isViewOnce)
                      TextButton(onPressed: _save, child: const Text('Kaydet')),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            attachment.bytes,
            height: 150,
            width: thumbnailWidth,
            cacheWidth:
                (thumbnailWidth * MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => SizedBox(
              height: 64,
              width: 200,
              child: Center(
                child: Text(
                  'Fotoğraf önizlenemiyor',
                  style: TextStyle(color: _color),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (attachment.kind == ChatAttachmentKind.audio) {
      return SizedBox(
        width: 220,
        child: Row(
          children: [
            IconButton(
              tooltip: _playing ? 'Duraklat' : 'Ses kaydını dinle',
              onPressed: _busy ? null : _play,
              color: _color,
              icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ses kaydı', style: TextStyle(color: _color)),
                  Text(
                    '${attachmentDuration(_position)} / ${attachmentDuration(attachment.duration ?? Duration.zero)}',
                    style: TextStyle(color: _color, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final size = attachment.bytes.length < 1024 * 1024
        ? '${(attachment.bytes.length / 1024).ceil()} KB'
        : '${(attachment.bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: _busy ? null : _save,
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: _color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _color),
                  ),
                  Text(size, style: TextStyle(fontSize: 11, color: _color)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dosyayı kaydet',
              onPressed: _busy ? null : _save,
              icon: Icon(Icons.download, color: _color),
            ),
          ],
        ),
      ),
    );
  }
}
