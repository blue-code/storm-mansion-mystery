import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

const Color _kGold = Color(0xFFD4A76A);

class _FontPreset {
  const _FontPreset(this.label, this.scale);
  final String label;
  final double scale;
}

const List<_FontPreset> _presets = [
  _FontPreset('작게', 0.85),
  _FontPreset('보통', 1.0),
  _FontPreset('크게', 1.2),
  _FontPreset('아주 크게', 1.4),
];

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(fontScaleProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121417),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _kGold.withOpacity(0.2), width: 1.5),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 그래버
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.settings, color: _kGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '설정',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.format_size,
                      color: Colors.white60, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '글씨 크기',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(scale * 100).round()}%',
                    style: const TextStyle(
                      color: _kGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 프리셋 선택 버튼
              Row(
                children: [
                  for (int i = 0; i < _presets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _PresetButton(
                        preset: _presets[i],
                        selected: (scale - _presets[i].scale).abs() < 0.001,
                        onTap: () => ref
                            .read(fontScaleProvider.notifier)
                            .setScale(_presets[i].scale),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // 미세 조정 슬라이더
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _kGold,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: _kGold,
                  overlayColor: _kGold.withOpacity(0.2),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: scale,
                  min: FontScaleNotifier.minScale,
                  max: FontScaleNotifier.maxScale,
                  divisions: ((FontScaleNotifier.maxScale -
                              FontScaleNotifier.minScale) /
                          0.05)
                      .round(),
                  onChanged: (v) =>
                      ref.read(fontScaleProvider.notifier).setScale(v),
                ),
              ),
              const SizedBox(height: 8),
              // 실시간 미리보기
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '미리보기',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '천둥이 저택을 흔들던 그 밤, 모두가 같은 질문을 떠올렸다. '
                      '누가 가장 먼저 그를 발견했는가?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15 * scale,
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _FontPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _kGold.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _kGold : Colors.white12,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            preset.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _kGold : Colors.white60,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SettingsSheet(),
  );
}
