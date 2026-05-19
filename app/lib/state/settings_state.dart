import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StoreSettings {
  final int dailyOrderLimit;
  final Map<String, String> messageTemplates;
  final int lateOrderHours; // an order in "inProduction" longer than this = late

  const StoreSettings({
    this.dailyOrderLimit = 20,
    this.messageTemplates = const {
      'submitted': 'Ciao {{name}}, abbiamo ricevuto il tuo ordine {{code}}. Ti aggiorniamo non appena è pronto.',
      'inProduction': 'Ciao {{name}}, stiamo lavorando al tuo ordine {{code}}.',
      'ready': 'Ciao {{name}}, il tuo ordine {{code}} è pronto per il ritiro! Ti aspettiamo in Via Vittorio Emanuele III, 205 — 80027 Frattamaggiore (NA). Orari: Lun-Sab 09:00-13:00.',
      'pickedUp': 'Ciao {{name}}, grazie per essere passato da Silvestre Fotoservizi! A presto.',
      'cancelled': 'Ciao {{name}}, il tuo ordine {{code}} è stato annullato. Se hai dubbi contattaci al +39 347 826 0320.',
    },
    this.lateOrderHours = 48,
  });

  Map<String, dynamic> toFirestore() => {
        'dailyOrderLimit': dailyOrderLimit,
        'messageTemplates': messageTemplates,
        'lateOrderHours': lateOrderHours,
      };

  factory StoreSettings.fromFirestore(Map<String, dynamic> data) =>
      StoreSettings(
        dailyOrderLimit: (data['dailyOrderLimit'] as num?)?.toInt() ?? 20,
        messageTemplates: Map<String, String>.from(
            (data['messageTemplates'] as Map?) ?? const {}),
        lateOrderHours: (data['lateOrderHours'] as num?)?.toInt() ?? 48,
      );
}

class SettingsState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StoreSettings _settings = const StoreSettings();
  bool _loaded = false;

  StoreSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final snap = await _db.collection('settings').doc('store').get();
      if (snap.exists) {
        _settings = StoreSettings.fromFirestore(snap.data()!);
      }
    } catch (_) {
      // Ignore — use defaults
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateDailyLimit(int v) async {
    _settings = StoreSettings(
      dailyOrderLimit: v,
      messageTemplates: _settings.messageTemplates,
      lateOrderHours: _settings.lateOrderHours,
    );
    await _save();
  }

  Future<void> updateTemplate(String key, String value) async {
    final t = Map<String, String>.from(_settings.messageTemplates);
    t[key] = value;
    _settings = StoreSettings(
      dailyOrderLimit: _settings.dailyOrderLimit,
      messageTemplates: t,
      lateOrderHours: _settings.lateOrderHours,
    );
    await _save();
  }

  Future<void> updateLateHours(int v) async {
    _settings = StoreSettings(
      dailyOrderLimit: _settings.dailyOrderLimit,
      messageTemplates: _settings.messageTemplates,
      lateOrderHours: v,
    );
    await _save();
  }

  Future<void> _save() async {
    await _db.collection('settings').doc('store').set(_settings.toFirestore());
    notifyListeners();
  }

  String renderTemplate(String key,
      {required String name, required String code}) {
    final tmpl = _settings.messageTemplates[key] ?? '';
    return tmpl
        .replaceAll('{{name}}', name)
        .replaceAll('{{code}}', code);
  }
}

final settingsState = SettingsState();
