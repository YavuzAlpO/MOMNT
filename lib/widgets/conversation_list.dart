import 'package:flutter/material.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/widgets/chat_avatar.dart';
import 'package:provider/provider.dart';

enum _ChatAction { pin, archive }

class ConversationList extends StatelessWidget {
  const ConversationList({
    super.key,
    required this.chats,
    required this.onOpen,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelection,
  });

  final List<ChatConversation> chats;
  final ValueChanged<String> onOpen;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggleSelection;

  String _timeLabel(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return TimeOfDay.fromDateTime(date).format(context);
    if (day == today.subtract(const Duration(days: 1))) return 'Dün';
    return '${date.day}.${date.month}';
  }

  void _apply(BuildContext context, ChatConversation chat, _ChatAction action) {
    final controller = context.read<MessagesController>();
    // Açık menünün eski değerine göre değil, güncel kayda göre değiştir.
    final current = controller.conversation(chat.contact.id);
    if (current == null) return;
    if (action == _ChatAction.pin) {
      controller.setPinned(current.contact.id, !current.isPinned);
    } else {
      controller.setArchived(current.contact.id, !current.isArchived);
    }
  }

  Future<void> _showActions(BuildContext context, ChatConversation chat) async {
    final action = await showModalBottomSheet<_ChatAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                chat.contact.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(chat.isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle'),
              onTap: () => Navigator.pop(sheetContext, _ChatAction.pin),
            ),
            ListTile(
              leading: Icon(
                chat.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              title: Text(chat.isArchived ? 'Arşivden çıkar' : 'Arşivle'),
              onTap: () => Navigator.pop(sheetContext, _ChatAction.archive),
            ),
          ],
        ),
      ),
    );
    if (action != null && context.mounted) _apply(context, chat, action);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            key: ValueKey('conversation-${chat.contact.id}'),
            selected: selectionMode && selectedIds.contains(chat.contact.id),
            selectedTileColor: const Color(0xFFE8ECF5),
            onTap: () => selectionMode
                ? onToggleSelection?.call(chat.contact.id)
                : onOpen(chat.contact.id),
            onLongPress: () => selectionMode
                ? onToggleSelection?.call(chat.contact.id)
                : _showActions(context, chat),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: selectionMode
                ? Checkbox(
                    key: ValueKey('select-conversation-${chat.contact.id}'),
                    value: selectedIds.contains(chat.contact.id),
                    onChanged: (_) => onToggleSelection?.call(chat.contact.id),
                  )
                : ChatAvatar(contact: chat.contact),
            title: Text(
              chat.contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2167),
              ),
            ),
            subtitle: Text(
              chat.lastMessage?.previewText ?? 'Henüz mesaj yok',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeLabel(context, chat.lastMessage?.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (chat.isPinned || chat.unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chat.isPinned)
                            const Tooltip(
                              message: 'Sabitlenmiş sohbet',
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Color(0xFF0F2167),
                              ),
                            ),
                          if (chat.isPinned && chat.unreadCount > 0)
                            const SizedBox(width: 4),
                          if (chat.unreadCount > 0)
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2167),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${chat.unreadCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (!selectionMode)
                  PopupMenuButton<_ChatAction>(
                    key: ValueKey('conversation-options-${chat.contact.id}'),
                    tooltip: 'Sohbet seçenekleri',
                    onSelected: (action) => _apply(context, chat, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _ChatAction.pin,
                        child: Text(
                          chat.isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
                        ),
                      ),
                      PopupMenuItem(
                        value: _ChatAction.archive,
                        child: Text(
                          chat.isArchived ? 'Arşivden çıkar' : 'Arşivle',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
