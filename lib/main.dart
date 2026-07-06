import 'dart:async';
import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/radar_screen.dart';
import 'screens/futures_screen.dart';
import 'screens/whale_screen.dart';

String? _startupError;

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // Arayüzü HEMEN göster. Servisler arka planda, zaman aşımlı olarak
    // başlatılacak - biri takılırsa veya hata verirse uygulama asla
    // beyaz ekranda donmayacak.
    runApp(const KriptoAlarmApp());

    _initServicesInBackground();
  }, (error, stack) {
    debugPrint('Yakalanamayan hata: $error\n$stack');
  });
}

void _initServicesInBackground() async {
  try {
    await NotificationService.init().timeout(const Duration(seconds: 8));
  } catch (e) {
    _startupError = 'Bildirim servisi başlatılamadı: $e';
    debugPrint('NotificationService init error: $e');
  }

  try {
    await initBackgroundService().timeout(const Duration(seconds: 8));
  } catch (e) {
    _startupError = (_startupError == null ? '' : '$_startupError\n\n') +
        'Arkaplan servisi başlatılamadı: $e';
    debugPrint('Background service init error: $e');
  }
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
  Timer? _errorCheckTimer;

  final _screens = const [
    HomeScreen(),
    RadarScreen(),
    FuturesScreen(),
    WhaleScreen(),
    AlarmScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Arka planda başlatılan servisler bittiğinde (veya zaman aşımına
    // uğradığında) olası hata mesajını yakalayıp ekranda göstermek için
    // birkaç kez kontrol et.
    int checks = 0;
    _errorCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checks++;
      if (mounted) setState(() {});
      if (checks > 10) timer.cancel();
    });
  }

  @override
  void dispose() {
    _errorCheckTimer?.cancel();
    super.dispose();
  }

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
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0E14),
        currentIndex: _index,
        selectedItemColor: const Color(0xFFF7931A),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'AI Radar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart), label: 'Futures'),
          BottomNavigationBarItem(icon: Icon(Icons.waves), label: 'Balina'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active), label: 'Alarmlar'),
        ],
      ),
    );
  }
}
