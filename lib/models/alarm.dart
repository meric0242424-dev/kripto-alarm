enum AlarmType { priceAbove, priceBelow, percentChange, rsiBelow, rsiAbove }

class PriceAlarm {
  final String id;
  final String symbol; // e.g. BTCUSDT
  final AlarmType type;
  final double targetValue;
  bool isActive;
  bool isTriggered;
  final DateTime createdAt;

  PriceAlarm({
    required this.id,
    required this.symbol,
    required this.type,
    required this.targetValue,
    this.isActive = true,
    this.isTriggered = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'type': type.name,
        'targetValue': targetValue,
        'isActive': isActive,
        'isTriggered': isTriggered,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PriceAlarm.fromJson(Map<String, dynamic> json) => PriceAlarm(
        id: json['id'],
        symbol: json['symbol'],
        type: AlarmType.values.firstWhere((e) => e.name == json['type']),
        targetValue: (json['targetValue'] as num).toDouble(),
        isActive: json['isActive'] ?? true,
        isTriggered: json['isTriggered'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  String describe() {
    switch (type) {
      case AlarmType.priceAbove:
        return '$symbol > $targetValue USDT olursa';
      case AlarmType.priceBelow:
        return '$symbol < $targetValue USDT olursa';
      case AlarmType.percentChange:
        return '$symbol %$targetValue değişirse';
      case AlarmType.rsiBelow:
        return '$symbol RSI < $targetValue olursa';
      case AlarmType.rsiAbove:
        return '$symbol RSI > $targetValue olursa';
    }
  }
}
