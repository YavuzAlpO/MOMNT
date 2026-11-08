import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:momnt/screens/home_tab_screen.dart';
import 'package:momnt/screens/map_tab_screen.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/screens/profile_tab_screen.dart';
import 'package:momnt/screens/requests_tab_screen.dart';
import 'package:momnt/state/check_in_controller.dart';
import 'package:momnt/widgets/check_in_manager_sheet.dart';
import 'package:momnt/services/demo_social_data.dart';
import 'package:momnt/state/messages_controller.dart';
import 'package:momnt/theme/momnt_theme.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MomntApp());
}

class MomntApp extends StatefulWidget {
  const MomntApp({super.key});

  @override
  State<MomntApp> createState() => _MomntAppState();
}

class _MomntAppState extends State<MomntApp> {
  late final CheckInController _checkInController = CheckInController();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AppLifecycleListener _lifecycle;
  bool _wasCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInController.addListener(_showCheckOutMessage);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          _checkInController.setForeground(state == AppLifecycleState.resumed),
    );
  }

  void _showCheckOutMessage() {
    final ended = _wasCheckedIn && !_checkInController.isCheckedIn;
    _wasCheckedIn = _checkInController.isCheckedIn;
    final message = _checkInController.lastError;
    if (!ended || message == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _checkInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CheckInScope(
      controller: _checkInController,
      child: ChangeNotifierProvider<MessagesController>(
        create: (_) => MessagesController.demo(contacts: demoMutualFollows),
        child: MaterialApp(
          scaffoldMessengerKey: _messengerKey,
          title: 'MOMNT',
          debugShowCheckedModeBanner: false,
          theme: buildMomntTheme(),
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _homeTab = 0;
  static const _mapTab = 1;
  static const _messagesTab = 2;
  static const _profileTab = 3;
  static const _minimumRequestSwipeDistance = 56.0;
  final _pages = PageController(initialPage: _mapTab);
  int _currentIndex = _mapTab;
  bool _showRequests = false;
  bool _openedRequests = false;
  bool _checkInOpen = false;
  double _requestSwipeStartX = 0;

  void _selectTab(int index) {
    if (_showRequests) setState(() => _showRequests = false);
    _pages.jumpToPage(index);
  }

  void _openRequests() {
    setState(() {
      _showRequests = true;
      _openedRequests = true;
    });
  }

  void _finishRequestsSwipe(DragEndDetails details) {
    final distance = details.localPosition.dx - _requestSwipeStartX;
    if (distance.abs() < _minimumRequestSwipeDistance) return;
    _selectTab(distance < 0 ? _messagesTab : _mapTab);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _openCheckIn() async {
    if (_checkInOpen) return;
    _checkInOpen = true;
    try {
      await showCheckInManager(context);
    } finally {
      _checkInOpen = false;
    }
  }

  Widget _navigationItem(
    int index,
    String label,
    IconData icon,
    IconData selectedIcon, {
    int unreadCount = 0,
  }) {
    final selected = !_showRequests && _currentIndex == index;
    final color = selected ? MomntColors.accent : MomntColors.muted;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );
    final tabIcon = Icon(selected ? selectedIcon : icon, color: color);
    return Expanded(
      child: Semantics(
        selected: selected,
        value: unreadCount > 0 ? '$unreadCount okunmamış mesaj' : null,
        child: InkWell(
          onTap: () => _selectTab(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unreadCount > 0)
                ExcludeSemantics(
                  child: Badge.count(
                    count: unreadCount,
                    maxCount: 99,
                    child: tabIcon,
                  ),
                )
              else
                tabIcon,
              const SizedBox(height: 4),
              Text(label, style: labelStyle, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  static const _screens = [
    HomeTabScreen(),
    MapTabScreen(),
    MessagesTabScreen(),
    ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scrollBehavior = ScrollConfiguration.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MOMNT',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        actions: [
          if (!_showRequests && _currentIndex == _homeTab)
            IconButton(
              tooltip: 'İstekler',
              onPressed: _openRequests,
              icon: const Icon(Icons.people_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _showRequests ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pages,
              scrollBehavior: scrollBehavior.copyWith(
                dragDevices: {
                  ...scrollBehavior.dragDevices,
                  PointerDeviceKind.mouse,
                },
              ),
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                final active = !_showRequests && _currentIndex == index;
                return _KeptTab(
                  child: ExcludeFocus(
                    excluding: !active,
                    child: TickerMode(enabled: active, child: _screens[index]),
                  ),
                );
              },
            ),
            if (_openedRequests)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragStart: (details) {
                  _requestSwipeStartX = details.localPosition.dx;
                },
                onHorizontalDragEnd: _finishRequestsSwipe,
                child: const RequestsTabScreen(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _navigationItem(
              _homeTab,
              'Ana Sayfa',
              Icons.home_outlined,
              Icons.home,
            ),
            _navigationItem(_mapTab, 'Harita', Icons.map_outlined, Icons.map),
            Expanded(
              child: Center(
                child: IconButton.filled(
                  key: const Key('check-in-navigation'),
                  tooltip: 'Check-in',
                  onPressed: _openCheckIn,
                  iconSize: 32,
                  padding: const EdgeInsets.all(10),
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
            Selector<MessagesController, int>(
              selector: (_, messages) => messages.unreadMessageCount,
              builder: (_, unreadCount, _) => _navigationItem(
                _messagesTab,
                'Mesajlar',
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                unreadCount: unreadCount,
              ),
            ),
            _navigationItem(
              _profileTab,
              'Profil',
              Icons.person_outline,
              Icons.person,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeptTab extends StatefulWidget {
  const _KeptTab({required this.child});

  final Widget child;

  @override
  State<_KeptTab> createState() => _KeptTabState();
}

class _KeptTabState extends State<_KeptTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
