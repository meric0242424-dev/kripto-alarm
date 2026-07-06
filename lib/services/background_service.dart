import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../models/alarm.dart';

const String kAlarmCheckTask = 'checkPriceAlarmsTask';

/// WorkManager tarafından arkaplanda (uygulama kapalıyken dahi) çağrılır.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kAlarmCheckTask) {
      await NotificationService.init();
      await checkAllAlarms();
    }
    return Future.value(true);
  });
}

Future<void> checkAllAlarms() async {
  final alarms = await StorageService.loadAlarms();
  final active = alarms.where((a) => a.isActive && !a.isTriggered).toList();
  if (active.isEmpty) return;

  // Aynı sembolü tekrar tekrar çekmemek için grupla
  final symbols = active.map((a) => a.symbol).toSet();
  final prices = <String, double>{};
  final rsiValues = <String, double>{};

  for (final symbol in symbols) {
    try {
      prices[symbol] = await ApiService.fetchPrice(symbol);
      final klines = await ApiService.fetchKlines(symbol, interval: '1h');
      final closes = ApiService.closePrices(klines);
      rsiValues[symbol] = ApiService.calculateRsi(closes);
    } catch (_) {
      // Ağ hatası olursa bu sembolü atla
    }
  }

  for (final alarm in active) {
    final price = prices[alarm.symbol];
    final rsi = rsiValues[alarm.symbol];
    if (price == null) continue;

    bool triggered = false;
    String message = '';

    switch (alarm.type) {
      case AlarmType.priceAbove:
        if (price >= alarm.targetValue) {
          triggered = true;
          message = '${alarm.symbol} ${alarm.targetValue} USDT üzerine çıktı! Şu an: $price';
        }
        break;
      case AlarmType.priceBelow:
        if (price <= alarm.targetValue) {
          triggered = true;
          message = '${alarm.symbol} ${alarm.targetValue} USDT altına düştü! Şu an: $price';
        }
        break;
      case AlarmType.percentChange:
        // percentChange alarmları için ayrı 24h değişim kontrolü gerekir
        break;
      case AlarmType.rsiBelow:
        if (rsi != null && rsi <= alarm.targetValue) {
          triggered = true;
          message = '${alarm.symbol} RSI ${rsi.toStringAsFixed(1)} - aşırı satım bölgesi!';
        }
        break;
      case AlarmType.rsiAbove:
        if (rsi != null && rsi >= alarm.targetValue) {
          triggered = true;
          message = '${alarm.symbol} RSI ${rsi.toStringAsFixed(1)} - aşırı alım bölgesi!';
        }
        break;
    }

    if (triggered) {
      await NotificationService.showAlarmTriggered(
        title: 'Kripto Alarm Merkezi',
        body: message,
      );
      alarm.isTriggered = true;
      await StorageService.updateAlarm(alarm);
    }
  }
}

Future<void> initBackgroundService() async {
  await Workmanager().initialize(
    backgroundCallbackDispatcher,
    isInDebugMode: false,
  );
  // Android'de minimum periyot 15 dakikadır.
  await Workmanager().registerPeriodicTask(
    'price-alarm-check',
    kAlarmCheckTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
