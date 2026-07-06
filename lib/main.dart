import 'dart:async';
import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_screen.dart';

String? _startupError;

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Başlangıç servislerini güvenli şekilde başlat.
    // Biri hata verirse uygulama çökmesin, sadece o özellik devre dışı kalsın.
    try {
      await NotificationService.init();
    } catch (e, st) {
      _startupError = 'Bildirim servisi başlatılamadı:\n$e';
      debugPrint('NotificationService init error: $e\n$st');
    }

    try {
      await initBackgroundService();
    } catch (e, st) {
      _startupError = (_startupError == null ? '' : '$_startupError\n\n') +
          'Arkaplan servisi başlatılamadı:\n$e';
      debugPrint('Background service init error: $e\n$st');
    }

    runApp(const KriptoAlarmApp());
  }, (error, stack) {
    debugPrint('Yakalanamayan hata: $error\n$stack');
  });
}

class KriptoAlarmApp extends StatelessWidget {
  const KriptoAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kripto Alarm Merkezi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFFF7931A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFFF7931A),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFF7931A)),
          ),
        ),
      ),
      home: const RootNav(),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    AlarmScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_startupError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade900,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Başlangıç uyarısı (uygulama yine de çalışıyor):\n$_startupError',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          Expanded(child: _screens[_index]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B0E14),
        currentIndex: _index,
        selectedItemColor: const Color(0xFFF7931A),
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active), label: 'Alarmlar'),
        ],
      ),
    );
  }
}
