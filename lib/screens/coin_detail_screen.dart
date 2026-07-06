import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/coin.dart';
import '../services/api_service.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;
  const CoinDetailScreen({super.key, required this.symbol});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  Coin? _coin;
  List<double> _closes = [];
  double _rsi = 50;
  Map<String, double> _macd = {'macd': 0, 'signal': 0};
  bool _loading = true;
  int _aiScore = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final coin = await ApiService.fetchCoinDetail(widget.symbol);
      final klines =
          await ApiService.fetchKlines(widget.symbol, interval: '1h', limit: 100);
      final closes = ApiService.closePrices(klines);
      final rsi = ApiService.calculateRsi(closes);
      final macd = ApiService.calculateMacd(closes);

      // Ortalama hacme göre basit hacim oranı (son mumun hacmi / ortalama)
      final volumes =
          klines.map((k) => double.parse(k[5].toString())).toList();
      final avgVol = volumes.reduce((a, b) => a + b) / volumes.length;
      final volumeRatio = avgVol == 0 ? 1.0 : volumes.last / avgVol;

      final score = AiScoreCalculator.calculate(
        changePercent24h: coin.changePercent24h,
        rsi: rsi,
        volumeRatio: volumeRatio,
      );

      setState(() {
        _coin = coin;
        _closes = closes;
        _rsi = rsi;
        _macd = macd;
        _aiScore = score;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: Text(widget.symbol),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _coin == null
              ? const Center(
                  child: Text('Veri alınamadı',
                      style: TextStyle(color: Colors.white70)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final coin = _coin!;
    final isUp = coin.changePercent24h >= 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('\$${coin.price.toStringAsFixed(coin.price < 1 ? 4 : 2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
        Text(
          '${isUp ? '+' : ''}${coin.changePercent24h.toStringAsFixed(2)}%  (24s)',
          style: TextStyle(
              color: isUp ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16),
        ),
        const SizedBox(height: 20),
        _card(
          child: SizedBox(
            height: 200,
            child: _closes.isEmpty
                ? const Center(
                    child: Text('Grafik verisi yok',
                        style: TextStyle(color: Colors.white54)))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < _closes.length; i++)
                              FlSpot(i.toDouble(), _closes[i]),
                          ],
                          isCurved: true,
                          color: isUp ? Colors.greenAccent : Colors.redAccent,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Piyasa Puanı',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('$_aiScore/100',
                      style: TextStyle(
                          color: _scoreColor(_aiScore),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _aiScore / 100,
                color: _scoreColor(_aiScore),
                backgroundColor: Colors.white12,
                minHeight: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _metricCard(
                    'RSI (14)', _rsi.toStringAsFixed(1), _rsiColor(_rsi))),
            const SizedBox(width: 12),
            Expanded(
                child: _metricCard('MACD',
                    _macd['macd']!.toStringAsFixed(4), Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _metricCard('24s Yüksek',
                    coin.high24h.toStringAsFixed(2), Colors.white)),
            const SizedBox(width: 12),
            Expanded(
                child: _metricCard(
                    '24s Düşük', coin.low24h.toStringAsFixed(2), Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _metricCard(String label, String value, Color color) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Color _scoreColor(int score) {
    if (score >= 70) return Colors.greenAccent;
    if (score >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _rsiColor(double rsi) {
    if (rsi < 30) return Colors.greenAccent;
    if (rsi > 70) return Colors.redAccent;
    return Colors.white;
  }
}
