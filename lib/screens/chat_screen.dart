import 'package:flutter/material.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/widgets/chat_avatar.dart';
import 'package:momnt/services/chat_media_service.dart';
import 'package:momnt/widgets/chat_composer.dart';
import 'package:momnt/widgets/chat_attachment_view.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contactId, this.mediaService});
  final String contactId;
  final ChatMediaService? mediaService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MessagesController _messages;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = context.read<MessagesController>();
  }

  bool _send(String text, ChatAttachment? attachment) {
    if (!_messages.sendMessage(
      widget.contactId,
      text,
      attachment: attachment,
    )) {
      return false;
    }
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    return true;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<MessagesController>().conversation(
      widget.contactId,
    );
    if (chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sohbet')),
        body: const Center(child: Text('Sohbet bulunamadı.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ChatAvatar(contact: chat.contact, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.contact.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    chat.contact.username,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFE8ECF5),
              child: const Text(
                'Demo sohbet: mesajlar karşı tarafa iletilmez ve uygulama kapanınca silinir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF0F2167)),
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const Center(child: Text('Sohbeti ilk mesajınla başlat.'))
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.messages.length,
                      itemBuilder: (_, index) => _MessageBubble(
                        key: ValueKey(
                          chat.messages[chat.messages.length - 1 - index].id,
                        ),
                        message:
                            chat.messages[chat.messages.length - 1 - index],
                        onOpenOnce: (id) =>
                            _messages.claimViewOncePhoto(widget.contactId, id),
                      ),
                    ),
            ),
            ChatComposer(
              initialText: _messages.draft(widget.contactId),
              onDraftChanged: (value) =>
                  _messages.setDraft(widget.contactId, value),
              onSend: _send,
              mediaService: widget.mediaService,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.onOpenOnce,
  });
  final ChatMessage message;
  final ChatAttachment? Function(String id) onOpenOnce;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(0, 640),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMine
              ? const Color(0xFF0F2167)
              : const Color(0xFFE8ECF5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.attachment != null) ...[
              ChatAttachmentView(
                attachment: message.attachment!,
                isMine: message.isMine,
                onOpenOnce: () => onOpenOnce(message.id),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.text.isNotEmpty)
              SelectableText(
                message.text,
                style: TextStyle(
                  color: message.isMine ? Colors.white : Colors.black87,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: message.isMine ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (message.readAt != null)
                  Tooltip(
                    message: message.isMine
                        ? 'Karşı taraf okudu'
                        : 'Bu mesajı okudun',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all,
                          size: 13,
                          color: message.isMine
                              ? const Color(0xFF90CAF9)
                              : const Color(0xFF0F2167),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          message.isMine ? 'Görüldü' : 'Okundu',
                          style: TextStyle(
                            fontSize: 10,
                            color: message.isMine
                                ? const Color(0xFF90CAF9)
                                : const Color(0xFF0F2167),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (message.isMine)
                  const Tooltip(
                    message:
                        'Mesaj yalnızca bu cihazda; karşı tarafa iletilmedi.',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.white70),
                        SizedBox(width: 3),
                        Text(
                          'Cihazda',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
