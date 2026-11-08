import 'dart:async';

import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:flutter/services.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/services/chat_media_service.dart';
import 'package:momnt/widgets/chat_attachment_view.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.initialText,
    required this.onDraftChanged,
    required this.onSend,
    this.mediaService,
  });
  final String initialText;
  final ValueChanged<String> onDraftChanged;
  final bool Function(String text, ChatAttachment? attachment) onSend;
  final ChatMediaService? mediaService;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _input;
  late final ChatMediaService _media;
  ChatAttachment? _attachment;
  Timer? _tick;
  final _watch = Stopwatch();
  bool _recording = false;
  bool _paused = false;
  bool _busy = false;
  static const _recordingLimit = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialText);
    _media = widget.mediaService ?? ChatMediaService();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _watch.stop();
    _input.dispose();
    unawaited(_media.dispose());
    super.dispose();
  }

  void _error(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ChatMediaException
              ? error.message
              : 'İşlem tamamlanamadı. Lütfen yeniden dene.',
        ),
      ),
    );
  }

  void _send() {
    if (_busy || _recording) return;
    final composing = _input.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;
    if (!widget.onSend(_input.text, _attachment)) return;
    _input.clear();
    setState(() => _attachment = null);
  }

  void _insertNewline() {
    final value = _input.value;
    if (value.composing.isValid && !value.composing.isCollapsed) return;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, '\n');
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
    widget.onDraftChanged(text);
  }

  Future<void> _pickAttachment() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final kind = await showModalBottomSheet<ChatAttachmentKind>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Fotoğraf'),
              onTap: () =>
                  Navigator.pop(sheetContext, ChatAttachmentKind.image),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Belge'),
              onTap: () =>
                  Navigator.pop(sheetContext, ChatAttachmentKind.document),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final attachment = await _media.pick(kind);
      if (mounted && attachment != null) {
        setState(() => _attachment = attachment);
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startRecording() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await _media.startRecording();
      if (!mounted) return;
      _watch
        ..reset()
        ..start();
      setState(() {
        _recording = true;
        _paused = false;
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_watch.elapsed >= _recordingLimit) {
          unawaited(_finishRecording());
        } else if (mounted) {
          setState(() {});
        }
      });
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_busy || _recording) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final photo = await _media.takePhoto(context);
      if (mounted && photo != null) setState(() => _attachment = photo);
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRecordingPause() async {
    if (_busy || !_recording) return;
    setState(() => _busy = true);
    try {
      if (_paused) {
        await _media.resumeRecording();
        if (!mounted) return;
        _watch.start();
      } else {
        await _media.pauseRecording();
        if (!mounted) return;
        _watch.stop();
      }
      setState(() => _paused = !_paused);
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishRecording({bool cancel = false}) async {
    if (_busy) return;
    _tick?.cancel();
    _watch.stop();
    setState(() => _busy = true);
    try {
      if (cancel) {
        await _media.cancelRecording();
      } else {
        final attachment = await _media.stopRecording();
        if (mounted) setState(() => _attachment = attachment);
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) {
        setState(() {
          _recording = false;
          _paused = false;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_attachment != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: MomntColors.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChatAttachmentView(
                          key: ObjectKey(_attachment),
                          attachment: _attachment!,
                          isDraft: true,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eki kaldır',
                        onPressed: _busy
                            ? null
                            : () => setState(() => _attachment = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (_attachment!.kind == ChatAttachmentKind.image)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final mode in PhotoVisibility.values)
                          ChoiceChip(
                            label: Text(
                              mode == PhotoVisibility.persistent
                                  ? 'Kalıcı'
                                  : 'Tek seferlik',
                            ),
                            avatar: Icon(
                              mode == PhotoVisibility.persistent
                                  ? Icons.image_outlined
                                  : Icons.looks_one_outlined,
                              size: 18,
                            ),
                            selected: _attachment!.photoVisibility == mode,
                            onSelected: _busy
                                ? null
                                : (_) => setState(
                                    () => _attachment = _attachment!
                                        .withPhotoVisibility(mode),
                                  ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          if (_recording)
            Row(
              children: [
                IconButton(
                  tooltip: 'Kaydı iptal et',
                  onPressed: _busy
                      ? null
                      : () => _finishRecording(cancel: true),
                  icon: const Icon(Icons.delete_outline),
                ),
                Icon(
                  Icons.fiber_manual_record,
                  color: _paused ? Colors.orange : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_paused ? 'Duraklatıldı' : 'Kayıt'} ${attachmentDuration(_watch.elapsed)} / ${attachmentDuration(_recordingLimit)}',
                  ),
                ),
                IconButton(
                  key: const Key('chat-recording-pause'),
                  tooltip: _paused ? 'Kayda devam et' : 'Kaydı duraklat',
                  onPressed: _busy ? null : _toggleRecordingPause,
                  icon: Icon(
                    _paused
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Kaydı durdur',
                  onPressed: _busy ? null : _finishRecording,
                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('chat-attach'),
                  tooltip: 'Fotoğraf veya belge ekle',
                  onPressed: _busy ? null : _pickAttachment,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): _send,
                      const SingleActivator(LogicalKeyboardKey.numpadEnter):
                          _send,
                      const SingleActivator(
                        LogicalKeyboardKey.enter,
                        shift: true,
                      ): _insertNewline,
                      const SingleActivator(
                        LogicalKeyboardKey.numpadEnter,
                        shift: true,
                      ): _insertNewline,
                    },
                    child: TextField(
                      key: const Key('chat-input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      enabled: !_busy,
                      textInputAction: TextInputAction.send,
                      onEditingComplete: () {},
                      onSubmitted: (_) => _send(),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: widget.onDraftChanged,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz…',
                        suffixIcon: IconButton(
                          key: const Key('chat-camera'),
                          tooltip: 'Fotoğraf çek',
                          onPressed: _busy ? null : _takePhoto,
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            color: MomntColors.accent.withValues(alpha: 0.35),
                            size: 21,
                          ),
                        ),
                        filled: true,
                        fillColor: MomntColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('chat-mic'),
                  tooltip: 'Ses kaydı başlat',
                  onPressed: _busy || _attachment != null
                      ? null
                      : _startRecording,
                  icon: const Icon(Icons.mic_none),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _input,
                  builder: (_, value, _) => IconButton.filled(
                    key: const Key('chat-send'),
                    tooltip: 'Gönder',
                    onPressed:
                        _busy ||
                            (value.text.trim().isEmpty && _attachment == null)
                        ? null
                        : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
