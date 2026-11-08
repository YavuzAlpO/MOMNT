import 'package:flutter/material.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:momnt/screens/chat_screen.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/widgets/chat_avatar.dart';
import 'package:momnt/widgets/conversation_list.dart';
import 'package:provider/provider.dart';

enum _MessagesMenuAction { readAll, select }

class MessagesTabScreen extends StatefulWidget {
  const MessagesTabScreen({super.key, this.archived = false});
  final bool archived;

  @override
  State<MessagesTabScreen> createState() => _MessagesTabScreenState();
}

class _MessagesTabScreenState extends State<MessagesTabScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _selecting = false;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) => setState(() {
    if (!_selected.add(id)) _selected.remove(id);
  });

  void _endSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  Widget _menu(MessagesController controller) =>
      PopupMenuButton<_MessagesMenuAction>(
        key: const Key('messages-menu'),
        tooltip: 'Mesaj menüsü',
        icon: const Icon(Icons.menu, color: MomntColors.accent),
        onSelected: (action) {
          if (action == _MessagesMenuAction.readAll) {
            controller.markAllRead();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tüm sohbetler okundu olarak işaretlendi.'),
              ),
            );
          } else {
            setState(() {
              _selecting = true;
              _selected.clear();
            });
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _MessagesMenuAction.readAll,
            child: Text('Tümünü okundu işaretle'),
          ),
          PopupMenuItem(
            value: _MessagesMenuAction.select,
            child: Text('Mesaj seç'),
          ),
        ],
      );

  void _openChat(BuildContext context, String contactId) {
    context.read<MessagesController>().openConversation(contactId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatScreen(contactId: contactId)),
    );
  }

  Future<void> _newChat(BuildContext context) async {
    final contacts = context.read<MessagesController>().contacts;
    final contactId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.65,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Yeni sohbet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? const Center(
                      child: Text('Henüz sohbet başlatabileceğin kişi yok.'),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (_, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: ChatAvatar(contact: contact),
                          title: Text(contact.name),
                          subtitle: Text(contact.username),
                          onTap: () => Navigator.pop(sheetContext, contact.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    if (contactId != null && context.mounted) _openChat(context, contactId);
  }

  Widget _selectionBar(
    MessagesController controller,
    List<ChatConversation> chats,
  ) {
    final selectedChats = chats
        .where((chat) => _selected.contains(chat.contact.id))
        .toList();
    final ids = selectedChats.map((chat) => chat.contact.id).toSet();
    final allSelected = chats.isNotEmpty && ids.length == chats.length;
    final allPinned =
        selectedChats.isNotEmpty &&
        selectedChats.every((chat) => chat.isPinned);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'Seçimi kapat',
              onPressed: _endSelection,
              icon: const Icon(Icons.close),
            ),
            Text(
              '${ids.length} seçildi',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: chats.isEmpty
                  ? null
                  : () => setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected.addAll(chats.map((chat) => chat.contact.id));
                      }
                    }),
              child: Text(allSelected ? 'Seçimi kaldır' : 'Tümünü seç'),
            ),
            IconButton(
              key: const Key('bulk-read'),
              tooltip: 'Seçilenleri okundu işaretle',
              onPressed: ids.isEmpty
                  ? null
                  : () => controller.markConversationsRead(ids),
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              key: const Key('bulk-archive'),
              tooltip: widget.archived
                  ? 'Seçilenleri arşivden çıkar'
                  : 'Seçilenleri arşivle',
              onPressed: ids.isEmpty
                  ? null
                  : () {
                      controller.setArchivedFor(ids, !widget.archived);
                      _endSelection();
                    },
              icon: Icon(
                widget.archived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
            ),
            IconButton(
              key: const Key('bulk-pin'),
              tooltip: allPinned
                  ? 'Seçilenlerin sabitlemesini kaldır'
                  : 'Seçilenleri sabitle',
              onPressed: ids.isEmpty
                  ? null
                  : () => controller.setPinnedFor(ids, !allPinned),
              icon: Icon(allPinned ? Icons.push_pin_outlined : Icons.push_pin),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MessagesController>();
    final textTheme = Theme.of(context).textTheme;
    final chats = controller.searchConversations(
      _search.text,
      archived: widget.archived,
    );
    final archiveCount = controller.archivedConversations.length;
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selecting)
            _selectionBar(controller, chats)
          else
            Align(alignment: Alignment.centerLeft, child: _menu(controller)),
          if (!widget.archived)
            Row(
              children: [
                Expanded(
                  child: Text('Mesajlar', style: textTheme.headlineSmall),
                ),
                if (!_selecting)
                  IconButton(
                    tooltip: 'Yeni sohbet',
                    onPressed: () => _newChat(context),
                    icon: const Icon(Icons.edit_square),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('conversation-search'),
            controller: _search,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() => _selected.clear()),
            onSubmitted: (_) => _searchFocus.unfocus(),
            decoration: InputDecoration(
              hintText: 'Kişi veya mesaj ara',
              prefixIcon: IconButton(
                tooltip: 'Ara',
                onPressed: _searchFocus.requestFocus,
                icon: const Icon(Icons.search),
              ),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _selected.clear());
                      },
                    ),
              filled: true,
              fillColor: MomntColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!widget.archived) ...[
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('archived-conversations'),
                leading: const Icon(
                  Icons.archive_outlined,
                  color: MomntColors.accent,
                ),
                title: const Text('Arşivlenmiş sohbetler'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$archiveCount'),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                enabled: !_selecting,
                onTap: _selecting
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const MessagesTabScreen(archived: true),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Text(
                      _search.text.trim().isNotEmpty
                          ? 'Aramana uygun sohbet bulunamadı.'
                          : widget.archived
                          ? 'Arşivlenmiş sohbetin yok.'
                          : archiveCount > 0
                          ? 'Sohbetlerine arşivlenmiş sohbetler bölümünden ulaşabilirsin.'
                          : 'Yeni sohbet düğmesiyle bir kişiye mesaj yaz.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ConversationList(
                    chats: chats,
                    onOpen: (id) => _openChat(context, id),
                    selectionMode: _selecting,
                    selectedIds: _selected,
                    onToggleSelection: _toggleSelection,
                  ),
          ),
        ],
      ),
    );
    return widget.archived
        ? Scaffold(
            appBar: AppBar(title: const Text('Arşivlenmiş sohbetler')),
            body: SafeArea(child: content),
          )
        : content;
  }
}
