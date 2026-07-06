import 'package:flutter/material.dart';

class WhaleTransaction {
  final String coin;
  final String amount;
  final String usdValue;
  final String direction; // "Borsa Girişi" or "Borsa Çıkışı"
  final String detail;
  final String timeAgo;

  WhaleTransaction({
    required this.coin,
    required this.amount,
    required this.usdValue,
    required this.direction,
    required this.detail,
    required this.timeAgo,
  });
}

class WhaleScreen extends StatelessWidget {
  const WhaleScreen({super.key});

  // NOT: Gerçek zamanlı balina verisi (Whale Alert, Arkham vb.) ücretli API
  // gerektiriyor. Aşağıdaki liste sadece arayüzü göstermek için örnek veridir.
  static final List<WhaleTransaction> _mockData = [
    WhaleTransaction(
      coin: 'ETH',
      amount: '34,510 ETH',
      usdValue: '\$115.42M',
      direction: 'Borsa Çıkışı',
      detail: 'Binance → Bilinmeyen Cüzdan',
      timeAgo: '5 dakika önce',
    ),
    WhaleTransaction(
      coin: 'BTC',
      amount: '1,250 BTC',
      usdValue: '\$86.21M',
      direction: 'Borsa Girişi',
      detail: 'Bilinmeyen Cüzdan → Binance',
      timeAgo: '15 dakika önce',
    ),
    WhaleTransaction(
      coin: 'ETH',
      amount: '8,500 ETH',
      usdValue: '\$29.45M',
      direction: 'Borsa Çıkışı',
      detail: 'Kraken → Bilinmeyen Cüzdan',
      timeAgo: '25 dakika önce',
    ),
    WhaleTransaction(
      coin: 'BTC',
      amount: '2,100 BTC',
      usdValue: '\$144.21M',
      direction: 'Borsa Girişi',
      detail: 'Coinbase → Binance',
      timeAgo: '35 dakika önce',
    ),
    WhaleTransaction(
      coin: 'ETH',
      amount: '560 ETH',
      usdValue: '\$1.95M',
      direction: 'Borsa Girişi',
      detail: 'OKX → Bilinmeyen Cüzdan',
      timeAgo: '1 saat önce',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: const Text('Balina Takibi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu ekran örnek (demo) veri gösteriyor. Gerçek zamanlı '
                    'balina takibi için ücretli bir veri servisi (Whale '
                    'Alert, Arkham vb.) entegrasyonu gerekir.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ..._mockData.map(_whaleTile),
        ],
      ),
    );
  }

  Widget _whaleTile(WhaleTransaction tx) {
    final isOutflow = tx.direction == 'Borsa Çıkışı';
    return Card(
      color: const Color(0xFF161B26),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isOutflow ? Colors.green.shade900 : Colors.red.shade900,
          child: Icon(
            isOutflow ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
          ),
        ),
        title: Text('${tx.amount} (${tx.usdValue})',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(tx.detail,
            style: const TextStyle(color: Colors.white70)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              tx.direction,
              style: TextStyle(
                color: isOutflow ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(tx.timeAgo,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
