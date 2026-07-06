class Coin {
  final String symbol; // e.g. BTCUSDT
  final String name; // e.g. BTC/USDT
  final double price;
  final double changePercent24h;
  final double volume24h;
  final double high24h;
  final double low24h;

  Coin({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
  });

  factory Coin.fromBinanceTicker(Map<String, dynamic> json) {
    final symbol = json['symbol'] as String;
    return Coin(
      symbol: symbol,
      name: _friendlyName(symbol),
      price: double.tryParse(json['lastPrice'].toString()) ?? 0,
      changePercent24h:
          double.tryParse(json['priceChangePercent'].toString()) ?? 0,
      volume24h: double.tryParse(json['quoteVolume'].toString()) ?? 0,
      high24h: double.tryParse(json['highPrice'].toString()) ?? 0,
      low24h: double.tryParse(json['lowPrice'].toString()) ?? 0,
    );
  }

  static String _friendlyName(String symbol) {
    if (symbol.endsWith('USDT')) {
      final base = symbol.substring(0, symbol.length - 4);
      return '$base/USDT';
    }
    return symbol;
  }
}

/// Basit AI Piyasa Puanı hesaplama (0-100)
/// Gerçek uygulamada daha gelişmiş modellerle değiştirilebilir.
class AiScoreCalculator {
  static int calculate({
    required double changePercent24h,
    required double rsi,
    required double volumeRatio, // güncel hacim / ortalama hacim
  }) {
    double score = 50;

    // Trend gücü (değişim yüzdesine göre) - ağırlık %40
    score += (changePercent24h.clamp(-20, 20)) * 1.0;

    // RSI - ağırlık %30 (aşırı satım fırsat, aşırı alım risk)
    if (rsi < 30) {
      score += 15; // fırsat
    } else if (rsi > 70) {
      score -= 15; // riskli
    }

    // Hacim artışı - ağırlık %30
    if (volumeRatio > 1.5) {
      score += 15;
    } else if (volumeRatio < 0.7) {
      score -= 10;
    }

    return score.clamp(0, 100).round();
  }
}
