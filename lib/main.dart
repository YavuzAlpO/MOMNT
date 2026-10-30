import 'package:flutter/material.dart';
import 'package:momnt/screens/home_tab_screen.dart';
import 'package:momnt/screens/map_tab_screen.dart';
import 'package:momnt/screens/messages_tab_screen.dart';
import 'package:momnt/screens/profile_tab_screen.dart';
import 'package:momnt/screens/requests_tab_screen.dart';
import 'package:momnt/state/check_in_controller.dart';

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
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F2167),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'İstekler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
