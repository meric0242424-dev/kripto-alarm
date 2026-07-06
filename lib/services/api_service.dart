import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin.dart';

class ApiService {
  static const String _base = 'https://api.binance.com/api/v3';

  /// Popüler coinlerin 24 saatlik ticker verisini çeker.
  static Future<List<Coin>> fetchTopCoins(List<String> symbols) async {
    final uri = Uri.parse(
        '$_base/ticker/24hr?symbols=${Uri.encodeComponent(jsonEncode(symbols))}');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Fiyat verisi alınamadı (${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => Coin.fromBinanceTicker(e)).toList();
  }

  /// Tek bir coinin güncel fiyatını çeker.
  static Future<double> fetchPrice(String symbol) async {
    final uri = Uri.parse('$_base/ticker/price?symbol=$symbol');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Fiyat alınamadı');
    }
    final data = jsonDecode(res.body);
    return double.parse(data['price'].toString());
  }

  /// Tek bir coinin 24 saatlik detaylı ticker verisi.
  static Future<Coin> fetchCoinDetail(String symbol) async {
    final uri = Uri.parse('$_base/ticker/24hr?symbol=$symbol');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Coin verisi alınamadı');
    }
    return Coin.fromBinanceTicker(jsonDecode(res.body));
  }

  /// Mum (kline) verisi - grafik ve RSI/MACD hesaplamaları için.
  /// interval: 15m, 1h, 4h, 1d vb.
  static Future<List<List<dynamic>>> fetchKlines(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    final uri = Uri.parse(
        '$_base/klines?symbol=$symbol&interval=$interval&limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Grafik verisi alınamadı');
    }
    final List data = jsonDecode(res.body);
    return data.cast<List<dynamic>>();
  }

  /// Kapanış fiyatlarını kline verisinden çıkarır.
  static List<double> closePrices(List<List<dynamic>> klines) {
    return klines.map((k) => double.parse(k[4].toString())).toList();
  }

  /// Basit RSI(14) hesaplama.
  static double calculateRsi(List<double> closes, {int period = 14}) {
    if (closes.length < period + 1) return 50;
    double gains = 0, losses = 0;
    for (int i = closes.length - period; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }
    if (losses == 0) return 100;
    final rs = (gains / period) / (losses / period);
    return 100 - (100 / (1 + rs));
  }

  /// Basit MACD hesaplama (12,26,9 EMA).
  static Map<String, double> calculateMacd(List<double> closes) {
    if (closes.length < 26) return {'macd': 0, 'signal': 0};
    final ema12 = _ema(closes, 12);
    final ema26 = _ema(closes, 26);
    final macdLine = <double>[];
    for (int i = 0; i < closes.length; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }
    final signalLine = _ema(macdLine, 9);
    return {
      'macd': macdLine.last,
      'signal': signalLine.last,
    };
  }

  static List<double> _ema(List<double> data, int period) {
    final k = 2 / (period + 1);
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(data[i] * k + result[i - 1] * (1 - k));
    }
    return result;
  }

  // ---- Futures (Vadeli İşlemler) verisi ----
  static const String _futuresBase = 'https://fapi.binance.com';

  /// Funding rate (bir sonraki fonlama oranı tahmini)
  static Future<double> fetchFundingRate(String symbol) async {
    final uri = Uri.parse('$_futuresBase/fapi/v1/premiumIndex?symbol=$symbol');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Funding rate alınamadı');
    final data = jsonDecode(res.body);
    return double.parse(data['lastFundingRate'].toString());
  }

  /// Long/Short hesap oranı (son 5 dakikalık)
  static Future<Map<String, double>> fetchLongShortRatio(String symbol) async {
    final uri = Uri.parse(
        '$_futuresBase/futures/data/globalLongShortAccountRatio?symbol=$symbol&period=5m&limit=1');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Long/Short oranı alınamadı');
    final List data = jsonDecode(res.body);
    if (data.isEmpty) throw Exception('Veri yok');
    final entry = data.first;
    return {
      'longAccount': double.parse(entry['longAccount'].toString()) * 100,
      'shortAccount': double.parse(entry['shortAccount'].toString()) * 100,
    };
  }

  /// Açık pozisyon miktarı (open interest)
  static Future<double> fetchOpenInterest(String symbol) async {
    final uri = Uri.parse('$_futuresBase/fapi/v1/openInterest?symbol=$symbol');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Açık pozisyon alınamadı');
    final data = jsonDecode(res.body);
    return double.parse(data['openInterest'].toString());
  }

  // ---- Korku & Açgözlülük Endeksi ----
  static Future<Map<String, dynamic>> fetchFearGreedIndex() async {
    final uri = Uri.parse('https://api.alternative.me/fng/?limit=1');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Korku & Açgözlülük verisi alınamadı');
    }
    final data = jsonDecode(res.body);
    final entry = data['data'][0];
    return {
      'value': int.parse(entry['value'].toString()),
      'classification': entry['value_classification'].toString(),
    };
  }
}
