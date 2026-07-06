import 'package:flutter/material.dart';
import '../models/coin.dart';
import '../services/api_service.dart';
import 'coin_detail_screen.dart';

const List<String> kTrackedSymbols = [
  'BTCUSDT',
  'ETHUSDT',
  'SOLUSDT',
  'AVAXUSDT',
  'MATICUSDT',
  'BNBUSDT',
  'XRPUSDT',
  'ADAUSDT',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Coin> _coins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coins = await ApiService.fetchTopCoins(kTrackedSymbols);
      setState(() {
        _coins = coins;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veri alınamadı, internetini kontrol et';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: const Text('Kripto Alarm Merkezi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    final gainers = [..._coins]
      ..sort((a, b) => b.changePercent24h.compareTo(a.changePercent24h));
    final losers = [..._coins]
      ..sort((a, b) => a.changePercent24h.compareTo(b.changePercent24h));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Piyasa Genel Görünüm'),
        ..._coins.map(_coinTile),
        const SizedBox(height: 20),
        _sectionTitle('En Çok Yükselenler'),
        ...gainers.take(3).map(_coinTile),
        const SizedBox(height: 20),
        _sectionTitle('En Çok Düşenler'),
        ...losers.take(3).map(_coinTile),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      );

  Widget _coinTile(Coin coin) {
    final isUp = coin.changePercent24h >= 0;
    return Card(
      color: const Color(0xFF161B26),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoinDetailScreen(symbol: coin.symbol),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isUp ? Colors.green.shade900 : Colors.red.shade900,
          child: Icon(isUp ? Icons.trending_up : Icons.trending_down,
              color: Colors.white),
        ),
        title: Text(coin.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '\$${coin.price.toStringAsFixed(coin.price < 1 ? 4 : 2)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          '${isUp ? '+' : ''}${coin.changePercent24h.toStringAsFixed(2)}%',
          style: TextStyle(
            color: isUp ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
