import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveCompareCard extends StatefulWidget {
  final List<double>? sampleSeries; // 0..1（見本）
  final List<double>? userSeries; // 0..1（あなた）
  final int fps; // 例: 200
  final String title; // 見出し

  const WaveCompareCard({
    super.key,
    required this.sampleSeries,
    required this.userSeries,
    this.fps = 200,
    this.title = '波形表示（見本: 青 / あなた: 赤）',
  });

  @override
  State<WaveCompareCard> createState() => _WaveCompareCardState();
}

class _WaveCompareCardState extends State<WaveCompareCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final hasData = (widget.sampleSeries?.isNotEmpty == true) &&
        (widget.userSeries?.isNotEmpty == true);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // ヘッダ（タイトル＋凡例＋折りたたみトグル）
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _LegendDot(color: Colors.blue, label: '見本'),
                  const SizedBox(width: 12),
                  _LegendDot(color: Colors.redAccent, label: 'あなた'),
                  const SizedBox(width: 12),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          // コンテンツ
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: AspectRatio(
                aspectRatio: 3, // 横長
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: hasData
                      ? _OverlayWaves(
                          sample: widget.sampleSeries!,
                          user: widget.userSeries!,
                        )
                      : const Center(
                          child: Text('波形データがありません',
                              style: TextStyle(color: Colors.black54))),
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

/// 2本の0..1系列を“全体が入るように”重ね描きするシンプルな波形
class _OverlayWaves extends StatelessWidget {
  final List<double> sample;
  final List<double> user;
  const _OverlayWaves({required this.sample, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TwoWavesPainter(sample: sample, user: user),
    );
  }
}

class _TwoWavesPainter extends CustomPainter {
  final List<double> sample;
  final List<double> user;
  static const double _pad = 10.0; // 上下パディング
  static const double _hScale = 0.95; // 高さスケール

  _TwoWavesPainter({required this.sample, required this.user});

  @override
  void paint(Canvas canvas, Size size) {
    if (sample.isEmpty && user.isEmpty) return;

    // 表示ポイント数を画面幅ピクセル程度に再サンプリングして描画を軽量化
    final n = math.max(120, size.width.round());
    final s = _resample(sample, n);
    final u = _resample(user, n);

    final h = math.max(1.0, size.height - _pad * 2);
    final baseY = size.height - _pad;
    final dx = (n <= 1) ? size.width : size.width / (n - 1);

    // 共通：水平線（0ライン）
    final basePaint = Paint()
      ..color = const Color(0x11000000)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), basePaint);

    // ライン描画ヘルパ
    Path _makePath(List<double> a) {
      final p = Path();
      for (int i = 0; i < n; i++) {
        final x = i * dx;
        final y = baseY - (a[i].clamp(0.0, 1.0) * h * _hScale);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    // 見本(青)
    final pSample = _makePath(s);
    final blue = Paint()
      ..isAntiAlias = true
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pSample, blue);

    // あなた(赤)
    final pUser = _makePath(u);
    final red = Paint()
      ..isAntiAlias = true
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pUser, red);
  }

  @override
  bool shouldRepaint(covariant _TwoWavesPainter old) =>
      old.sample != sample || old.user != user;

  // 線形補間で n 点にリサンプリング
  static List<double> _resample(List<double> src, int n) {
    if (n <= 1) return [src.isEmpty ? 0 : src.first];
    if (src.isEmpty) return List.filled(n, 0.0);

    final out = List<double>.filled(n, 0.0);
    final step = (src.length - 1) / (n - 1);
    for (int i = 0; i < n; i++) {
      final t = i * step;
      final i0 = t.floor();
      final i1 = math.min(i0 + 1, src.length - 1);
      final frac = t - i0;
      out[i] = src[i0] * (1 - frac) + src[i1] * frac;
    }
    return out;
  }
}
