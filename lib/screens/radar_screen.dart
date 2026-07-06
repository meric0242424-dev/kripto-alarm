import 'package:flutter/material.dart';
import '../models/coin.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RadarItem {
  final Coin coin;
  final int score;
  RadarItem(this.coin, this.score);
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  List<RadarItem> _items = [];
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
      final items = <RadarItem>[];
      for (final coin in coins) {
        try {
          final klines =
              await ApiService.fetchKlines(coin.symbol, interval: '1h', limit: 50);
          final closes = ApiService.closePrices(klines);
          final rsi = ApiService.calculateRsi(closes);
          final volumes =
              klines.map((k) => double.parse(k[5].toString())).toList();
          final avgVol = volumes.reduce((a, b) => a + b) / volumes.length;
          final volumeRatio = avgVol == 0 ? 1.0 : volumes.last / avgVol;
          final score = AiScoreCalculator.calculate(
            changePercent24h: coin.changePercent24h,
            rsi: rsi,
            volumeRatio: volumeRatio,
          );
          items.add(RadarItem(coin, score));
        } catch (_) {
          // Bu coin için veri alınamazsa atla
        }
      }
      items.sort((a, b) => b.score.compareTo(a.score));
      setState(() {
        _items = items;
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
        title: const Text('AI Radar'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Bugün Dikkat Çekenler',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._items.take(4).map(_radarTile),
                      const SizedBox(height: 24),
                      const Text('Riskli Coinler',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._items.reversed.take(4).map(_radarTile),
                    ],
                  ),
                ),
    );
  }

  Widget _radarTile(RadarItem item) {
    return Card(
      color: const Color(0xFF161B26),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.coin.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '\$${item.coin.price.toStringAsFixed(item.coin.price < 1 ? 4 : 2)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _scoreColor(item.score).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.score}/100',
            style: TextStyle(
                color: _scoreColor(item.score), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return Colors.greenAccent;
    if (score >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
