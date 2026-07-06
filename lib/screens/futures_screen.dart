import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class FuturesData {
  final String symbol;
  double? fundingRate;
  double? longPercent;
  double? shortPercent;
  double? openInterest;
  String? error;

  FuturesData(this.symbol);
}

class FuturesScreen extends StatefulWidget {
  const FuturesScreen({super.key});

  @override
  State<FuturesScreen> createState() => _FuturesScreenState();
}

class _FuturesScreenState extends State<FuturesScreen> {
  List<FuturesData> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Tüm coinlerin futures verisini AYNI ANDA (paralel) çek
    final futures = kTrackedSymbols.map((symbol) async {
      final item = FuturesData(symbol);
      try {
        item.fundingRate = await ApiService.fetchFundingRate(symbol);
      } catch (e) {
        item.error = 'Funding rate alınamadı';
      }
      try {
        final ratio = await ApiService.fetchLongShortRatio(symbol);
        item.longPercent = ratio['longAccount'];
        item.shortPercent = ratio['shortAccount'];
      } catch (e) {
        item.error = (item.error ?? '') + ' Long/Short alınamadı';
      }
      try {
        item.openInterest = await ApiService.fetchOpenInterest(symbol);
      } catch (e) {
        // sessizce atla
      }
      return item;
    }).toList();

    final results = await Future.wait(futures);
    setState(() {
      _data = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: const Text('Futures Radar'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _data.map(_futuresCard).toList(),
              ),
            ),
    );
  }

  Widget _futuresCard(FuturesData item) {
    final hasLongShort = item.longPercent != null && item.shortPercent != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.symbol,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (item.fundingRate != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Funding Rate',
                    style: TextStyle(color: Colors.white54)),
                Text(
                  '${(item.fundingRate! * 100).toStringAsFixed(4)}%',
                  style: TextStyle(
                    color: item.fundingRate! >= 0
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (hasLongShort) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Long %${item.longPercent!.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                Text('Short %${item.shortPercent!.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: (item.longPercent! * 10).round().clamp(1, 1000),
                    child: Container(height: 8, color: Colors.greenAccent),
                  ),
                  Expanded(
                    flex: (item.shortPercent! * 10).round().clamp(1, 1000),
                    child: Container(height: 8, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
          if (item.openInterest != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Açık Pozisyon',
                    style: TextStyle(color: Colors.white54)),
                Text(item.openInterest!.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
          if (item.error != null && item.fundingRate == null && !hasLongShort)
            Text('Veri alınamadı',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
