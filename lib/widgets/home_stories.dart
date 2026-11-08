import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:momnt/models/chat_message.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:provider/provider.dart';

class HomeStory {
  const HomeStory({
    required this.name,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    this.contactId,
  });

  final String name;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final String? contactId;
}

class HomeStories extends StatefulWidget {
  const HomeStories({super.key, required this.stories});

  final List<HomeStory> stories;

  @override
  State<HomeStories> createState() => _HomeStoriesState();
}

class _HomeStoriesState extends State<HomeStories> {
  final _viewed = <HomeStory>{};
  final _liked = <HomeStory>{};

  void _toggleLike(HomeStory story) {
    if (!_liked.add(story)) _liked.remove(story);
  }

  void _markViewed(HomeStory story) {
    if (mounted && !_viewed.contains(story)) {
      setState(() => _viewed.add(story));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = [
      for (final story in widget.stories)
        if (!_viewed.contains(story)) story,
      ..._viewed.where(widget.stories.contains),
    ];
    if (stories.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Henüz hikâye yok.', style: TextStyle(fontSize: 12)),
      );
    }
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: behavior.copyWith(
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final story = stories[index];
          final viewed = _viewed.contains(story);
          return SizedBox(
            width: 66,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _markViewed(story);
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => _StoryViewer(
                      stories: stories,
                      start: index,
                      onViewed: _markViewed,
                      isLiked: _liked.contains,
                      onToggleLike: _toggleLike,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: viewed
                            ? const Color(0xFFD1D5DB)
                            : MomntColors.accent,
                        width: viewed ? 1 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        story.avatarUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: MomntColors.soft,
                          child: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    story.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryViewer extends StatefulWidget {
  const _StoryViewer({
    required this.stories,
    required this.start,
    required this.onViewed,
    required this.isLiked,
    required this.onToggleLike,
  });

  final List<HomeStory> stories;
  final int start;
  final ValueChanged<HomeStory> onViewed;
  final bool Function(HomeStory) isLiked;
  final ValueChanged<HomeStory> onToggleLike;

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late int _index = widget.start;
  late final _pages = PageController(initialPage: widget.start);
  final _replyInputs = <HomeStory, TextEditingController>{};
  final _replyFocus = FocusNode();
  String? _replyStatus;

  @override
  void dispose() {
    _pages.dispose();
    _replyFocus.dispose();
    for (final input in _replyInputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  void _sendReply(
    HomeStory story,
    String contactId,
    TextEditingController input,
  ) {
    final value = input.value;
    if (value.text.trim().isEmpty || !value.composing.isCollapsed) return;
    final sent = context.read<MessagesController>().sendMessage(
      contactId,
      value.text,
      storyReply: StoryReply(imageUrl: story.imageUrl, caption: story.caption),
    );
    if (sent) {
      input.clear();
      _replyFocus.unfocus();
    }
    setState(() {
      _replyStatus = sent ? 'Yanıt sohbete eklendi.' : 'Yanıt eklenemedi.';
    });
  }

  Widget _replyBar(HomeStory story, String contactId) {
    final input = _replyInputs.putIfAbsent(story, TextEditingController.new);
    final liked = widget.isLiked(story);
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide(color: Colors.white54),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: ObjectKey(story),
                controller: input,
                focusNode: _replyFocus,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.send,
                onChanged: (_) {
                  if (_replyStatus != null) setState(() => _replyStatus = null);
                },
                onSubmitted: (_) => _sendReply(story, contactId, input),
                decoration: InputDecoration(
                  hintText: 'Yanıt yaz…',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: false,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: input,
                    builder: (context, value, _) => IconButton(
                      tooltip: 'Yanıtı gönder',
                      color: Colors.white,
                      disabledColor: Colors.white38,
                      onPressed: value.text.trim().isEmpty
                          ? null
                          : () => _sendReply(story, contactId, input),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: liked ? 'Beğeniyi kaldır' : 'Hikâyeyi beğen',
              isSelected: liked,
              color: Colors.white,
              onPressed: () => setState(() => widget.onToggleLike(story)),
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(
                Icons.favorite,
                color: Color(0xFFFF5470),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    final contactId = story.contactId;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(story.name, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          tooltip: 'Hikâyeyi kapat',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.stories.length,
                onPageChanged: (index) {
                  _replyFocus.unfocus();
                  setState(() {
                    _index = index;
                    _replyStatus = null;
                  });
                  widget.onViewed(widget.stories[index]);
                },
                itemBuilder: (context, index) {
                  final story = widget.stories[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.network(
                            story.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Text(
                              'Hikâye görseli açılamadı.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          story.caption,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Önceki hikâye',
                  color: Colors.white,
                  disabledColor: Colors.white30,
                  onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_index + 1} / ${widget.stories.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Sonraki hikâye',
                  color: Colors.white,
                  disabledColor: Colors.white30,
                  onPressed: _index + 1 < widget.stories.length
                      ? () => _goTo(_index + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            if (_replyStatus case final status?)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            if (contactId != null) _replyBar(story, contactId),
          ],
        ),
      ),
    );
  }
}
