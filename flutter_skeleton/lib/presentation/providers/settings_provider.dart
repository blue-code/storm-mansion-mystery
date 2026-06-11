import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_provider.dart';

/// 본문(스토리/선택지) 글씨 크기 배율. 0.85(작게) ~ 1.5(아주 크게), 기본 1.0.
/// SharedPreferences 에 영속화되어 앱을 다시 켜도 유지된다.
final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FontScaleNotifier(prefs);
});

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier(this.prefs) : super(_load(prefs));

  final SharedPreferences prefs;
  static const String _key = 'text_font_scale';
  static const double minScale = 0.85;
  static const double maxScale = 1.5;

  static double _load(SharedPreferences prefs) {
    final v = prefs.getDouble(_key) ?? 1.0;
    return v.clamp(minScale, maxScale).toDouble();
  }

  void setScale(double value) {
    final clamped = value.clamp(minScale, maxScale).toDouble();
    if (clamped == state) return;
    state = clamped;
    prefs.setDouble(_key, clamped);
  }
}
