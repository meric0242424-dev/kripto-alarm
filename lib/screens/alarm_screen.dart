import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/background_service.dart';
import 'home_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<PriceAlarm> _alarms = [];
  String _selectedSymbol = kTrackedSymbols.first;
  AlarmType _selectedType = AlarmType.priceAbove;
  final TextEditingController _valueController = TextEditingController();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.loadAlarms();
    setState(() => _alarms = alarms);
  }

  Future<void> _createAlarm() async {
    final value = double.tryParse(_valueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir değer gir')),
      );
      return;
    }
    final alarm = PriceAlarm(
      id: const Uuid().v4(),
      symbol: _selectedSymbol,
      type: _selectedType,
      targetValue: value,
      createdAt: DateTime.now(),
    );
    await StorageService.addAlarm(alarm);
    _valueController.clear();
    await _loadAlarms();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm kaydedildi')),
      );
    }
  }

  Future<void> _deleteAlarm(String id) async {
    await StorageService.removeAlarm(id);
    await _loadAlarms();
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    try {
      await checkAllAlarms();
      await _loadAlarms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kontrol tamamlandı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kontrol hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: const Text('Alarm Merkezi'),
        actions: [
          _checking
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.bolt),
                  tooltip: 'Şimdi Kontrol Et',
                  onPressed: _checkNow,
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCreateForm(),
          const SizedBox(height: 24),
          const Text('Aktif Alarmlar',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_alarms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz alarm yok',
                  style: TextStyle(color: Colors.white54)),
            ),
          ..._alarms.map(_alarmTile),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yeni Alarm',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSymbol,
            dropdownColor: const Color(0xFF161B26),
            decoration: const InputDecoration(labelText: 'Coin Seç'),
            style: const TextStyle(color: Colors.white),
            items: kTrackedSymbols
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSymbol = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AlarmType>(
            value: _selectedType,
            dropdownColor: const Color(0xFF161B26),
            decoration: const InputDecoration(labelText: 'Alarm Türü'),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(
                  value: AlarmType.priceAbove, child: Text('Fiyat üzerine çıkarsa')),
              DropdownMenuItem(
                  value: AlarmType.priceBelow, child: Text('Fiyat altına düşerse')),
              DropdownMenuItem(
                  value: AlarmType.rsiBelow, child: Text('RSI altına düşerse')),
              DropdownMenuItem(
                  value: AlarmType.rsiAbove, child: Text('RSI üzerine çıkarsa')),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Hedef Değer'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createAlarm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Alarmı Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alarmTile(PriceAlarm alarm) {
    return Card(
      color: const Color(0xFF161B26),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(alarm.describe(),
            style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          alarm.isTriggered ? 'Tetiklendi' : 'Bekliyor',
          style: TextStyle(
              color: alarm.isTriggered ? Colors.orangeAccent : Colors.greenAccent),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteAlarm(alarm.id),
        ),
      ),
    );
  }
}
