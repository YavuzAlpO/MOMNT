import 'package:flutter/foundation.dart';
import 'package:momnt/models/chat_attachment.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/models/mutual_follow_profile.dart';

class ChatConversation {
  const ChatConversation({
    required this.contact,
    this.messages = const [],
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
  });

  final MutualFollowProfile contact;
  final List<ChatMessage> messages;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  ChatConversation copyWith({
    List<ChatMessage>? messages,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
  }) => ChatConversation(
    contact: contact,
    messages: messages ?? this.messages,
    unreadCount: unreadCount ?? this.unreadCount,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
  );
}

/// Demo mesajlaşma state'i. Uygulama kapanınca silinir; ağ üzerinden iletmez.
class MessagesController extends ChangeNotifier {
  MessagesController({
    required List<MutualFollowProfile> contacts,
    List<ChatConversation> initialConversations = const [],
  }) : contacts = List.unmodifiable(contacts) {
    for (final chat in initialConversations) {
      if (contacts.any((contact) => contact.id == chat.contact.id)) {
        _conversations[chat.contact.id] = ChatConversation(
          contact: chat.contact,
          messages: List.unmodifiable(chat.messages),
          unreadCount: chat.unreadCount,
          isPinned: chat.isPinned,
          isArchived: chat.isArchived,
        );
      }
    }
  }

  factory MessagesController.demo({
    required List<MutualFollowProfile> contacts,
  }) {
    final controller = MessagesController(contacts: contacts);
    final now = DateTime.now();
    for (final contact in contacts.take(2)) {
      final first = contact.id == 'mert-yilmaz';
      controller._conversations[contact.id] = ChatConversation(
        contact: contact,
        unreadCount: first ? 1 : 0,
        messages: [
          ChatMessage(
            id: 'demo-${contact.id}',
            text: first
                ? "Selam! Moda Kahve'de misin hâlâ?"
                : 'Harika, 10 dakikaya oradayım!',
            createdAt: now.subtract(
              first ? const Duration(minutes: 8) : const Duration(days: 1),
            ),
            isMine: false,
          ),
        ],
      );
    }
    return controller;
  }

  final List<MutualFollowProfile> contacts;
  final Map<String, ChatConversation> _conversations = {};
  final Map<String, String> _drafts = {};
  int _nextMessageId = 0;

  List<ChatConversation> get conversations {
    return _sorted(_conversations.values.where((chat) => !chat.isArchived));
  }

  List<ChatConversation> get archivedConversations =>
      _sorted(_conversations.values.where((chat) => chat.isArchived));

  int get unreadMessageCount =>
      _conversations.values.fold(0, (total, chat) => total + chat.unreadCount);

  List<ChatConversation> _sorted(Iterable<ChatConversation> chats) {
    final result = chats.toList();
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final byTime = (b.lastMessage?.createdAt ?? DateTime(1970)).compareTo(
        a.lastMessage?.createdAt ?? DateTime(1970),
      );
      return byTime != 0 ? byTime : a.contact.id.compareTo(b.contact.id);
    });
    return List.unmodifiable(result);
  }

  void setPinned(String contactId, bool pinned) {
    setPinnedFor([contactId], pinned);
  }

  void setArchived(String contactId, bool archived) {
    setArchivedFor([contactId], archived);
  }

  void setPinnedFor(Iterable<String> contactIds, bool pinned) {
    var changed = false;
    for (final id in contactIds.toSet()) {
      final current = _conversations[id];
      if (current == null || current.isPinned == pinned) continue;
      _conversations[id] = current.copyWith(isPinned: pinned);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void setArchivedFor(Iterable<String> contactIds, bool archived) {
    var changed = false;
    for (final id in contactIds.toSet()) {
      final current = _conversations[id];
      if (current == null || current.isArchived == archived) continue;
      _conversations[id] = current.copyWith(isArchived: archived);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void markConversationsRead(Iterable<String> contactIds) {
    final now = DateTime.now();
    var changed = false;
    for (final id in contactIds.toSet()) {
      final current = _conversations[id];
      if (current == null) continue;
      if (current.unreadCount == 0 &&
          !current.messages.any(
            (message) => !message.isMine && message.readAt == null,
          )) {
        continue;
      }
      _conversations[id] = current.copyWith(
        unreadCount: 0,
        messages: List.unmodifiable([
          for (final message in current.messages)
            if (!message.isMine && message.readAt == null)
              message.markRead(now)
            else
              message,
        ]),
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void markAllRead() => markConversationsRead(_conversations.keys.toList());

  List<ChatConversation> searchConversations(
    String query, {
    bool archived = false,
  }) {
    final chats = archived ? archivedConversations : conversations;
    final needle = _searchKey(query.trim());
    if (needle.isEmpty) return chats;
    return List.unmodifiable(
      chats.where(
        (chat) =>
            _searchKey(chat.contact.name).contains(needle) ||
            _searchKey(chat.contact.username).contains(needle) ||
            chat.messages.any(
              (message) =>
                  _searchKey(message.text).contains(needle) ||
                  (message.attachment != null &&
                      _searchKey(
                        '${message.attachment!.name} ${message.attachment!.previewText}',
                      ).contains(needle)),
            ),
      ),
    );
  }

  String _searchKey(String text) => text
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i\u0307', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  ChatConversation? conversation(String contactId) => _conversations[contactId];
  String draft(String contactId) => _drafts[contactId] ?? '';

  void setDraft(String contactId, String text) {
    if (text.isEmpty) {
      _drafts.remove(contactId);
    } else {
      _drafts[contactId] = text;
    }
  }

  void openConversation(String contactId) {
    final matches = contacts.where((contact) => contact.id == contactId);
    if (matches.isEmpty) return;
    final previous = _conversations[contactId];
    final hasUnread =
        previous?.messages.any(
          (message) => !message.isMine && message.readAt == null,
        ) ??
        false;
    if (previous != null && previous.unreadCount == 0 && !hasUnread) return;
    final readAt = DateTime.now();
    _conversations[contactId] =
        (previous ?? ChatConversation(contact: matches.first)).copyWith(
          unreadCount: 0,
          messages: List.unmodifiable([
            for (final message in previous?.messages ?? <ChatMessage>[])
              if (!message.isMine && message.readAt == null)
                message.markRead(readAt)
              else
                message,
          ]),
        );
    notifyListeners();
  }

  bool sendMessage(
    String contactId,
    String text, {
    DateTime? now,
    ChatAttachment? attachment,
    StoryReply? storyReply,
  }) {
    final trimmed = text.trim();
    var current = _conversations[contactId];
    if (current == null && storyReply != null) {
      final contact = contacts
          .where((item) => item.id == contactId)
          .firstOrNull;
      if (contact != null) current = ChatConversation(contact: contact);
    }
    if ((trimmed.isEmpty && attachment == null) || current == null) {
      return false;
    }
    if (attachment != null &&
        (attachment.bytes.isEmpty ||
            attachment.bytes.length > ChatAttachment.maxBytes)) {
      return false;
    }
    final message = ChatMessage(
      id: 'local-${_nextMessageId++}',
      text: trimmed,
      createdAt: now ?? DateTime.now(),
      isMine: true,
      attachment: attachment,
      storyReply: storyReply,
    );
    _conversations[contactId] = current.copyWith(
      unreadCount: storyReply == null ? 0 : current.unreadCount,
      messages: List.unmodifiable([...current.messages, message]),
    );
    if (storyReply == null) _drafts.remove(contactId);
    notifyListeners();
    return true;
  }

  /// Yalnız alıcı açabilir. Görüntü verisi senkron olarak bir kez teslim edilir.
  ChatAttachment? claimViewOncePhoto(String contactId, String messageId) {
    final current = _conversations[contactId];
    if (current == null) return null;
    final index = current.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return null;
    final message = current.messages[index];
    final attachment = message.attachment;
    if (message.isMine ||
        attachment == null ||
        !attachment.isViewOnce ||
        attachment.openedAt != null ||
        attachment.bytes.isEmpty) {
      return null;
    }
    final time = DateTime.now();
    final messages = [...current.messages];
    messages[index] = message
        .withAttachment(attachment.consumed(time))
        .markRead(time);
    _conversations[contactId] = current.copyWith(
      messages: List.unmodifiable(messages),
      unreadCount: messages
          .where((message) => !message.isMine && message.readAt == null)
          .length,
    );
    notifyListeners();
    return attachment;
  }
}
