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

  @override
  void dispose() {
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
          title: 'MOMNT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            primaryColor: const Color(0xFF0F2167),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F2167),
              primary: const Color(0xFF0F2167),
            ),
            useMaterial3: true,
          ),
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
  int _currentIndex = 1;
  bool _checkInOpen = false;

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
    IconData selectedIcon,
  ) {
    final selected = _currentIndex == index;
    final color = selected ? const Color(0xFF0F2167) : Colors.grey;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const MapTabScreen(),
    const RequestsTabScreen(),
    const MessagesTabScreen(),
    const ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOMNT'),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              tooltip: 'İstekler',
              onPressed: () => setState(() => _currentIndex = 2),
              icon: const Icon(Icons.people_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _navigationItem(0, 'Ana Sayfa', Icons.home_outlined, Icons.home),
            _navigationItem(1, 'Harita', Icons.map_outlined, Icons.map),
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
            _navigationItem(
              3,
              'Mesajlar',
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
            ),
            _navigationItem(4, 'Profil', Icons.person_outline, Icons.person),
          ],
        ),
      ),
    );
  }
}
