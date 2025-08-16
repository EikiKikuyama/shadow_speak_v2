import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shadow_speak_v2/models/word_segment.dart';

class LineWavePainter extends CustomPainter {
  final List<double> amplitudes; // 0..1 （等間隔, 推奨200サンプル/秒）
  final double progress; // 0..1 再生位置
  final int samplesPerSecond; // 200 = 5ms刻み
  final int displaySeconds; // 可視窓秒数
  final Color waveColor;
  final bool showCenterLine; // 固定ライン
  final bool showMovingDot; // 現在位置ドット
  final double heightScale; // 0.0..1.0

  LineWavePainter({
    required this.amplitudes,
    required this.progress,
    this.samplesPerSecond = 200,
    this.displaySeconds = 3,
    this.waveColor = Colors.blueAccent,
    this.showCenterLine = false,
    this.showMovingDot = true,
    this.heightScale = 0.95,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final total = amplitudes.length;
    final dispRaw = samplesPerSecond * displaySeconds;
    final disp = math.min(dispRaw, total);
    final safeProg = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    final centerIdx = (safeProg * (total - 1)).round();
    final half = disp ~/ 2;
    final start = math.max(0, math.min(centerIdx - half, total - disp));
    final end = start + disp;

    final unitW = disp > 1 ? size.width / (disp - 1) : size.width;

    // 波形
    final path = Path();
    for (int i = start; i < end; i++) {
      final x = (i - start) * unitW;
      final y = size.height -
          (amplitudes[i].clamp(0.0, 1.0) * size.height * heightScale);
      if (i == start)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    final wavePaint = Paint()
      ..isAntiAlias = true
      ..color = waveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, wavePaint);

    // 任意: 中央ライン
    if (showCenterLine) {
      final cx = size.width / 2;
      final glow = Paint()
        ..color = Colors.red.withOpacity(0.12)
        ..strokeWidth = 8;
      final red = Paint()
        ..color = Colors.red
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), glow);
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), red);
    }

    // 現在位置ドット
    if (showMovingDot) {
      final dotX = (centerIdx - start) * unitW;
      final amp = amplitudes[centerIdx.clamp(0, total - 1)];
      final dotY = size.height - (amp * size.height * heightScale);
      final halo = Paint()..color = Colors.red.withOpacity(0.18);
      final fill = Paint()..color = Colors.red;
      canvas.drawCircle(Offset(dotX, dotY), 9, halo);
      canvas.drawCircle(Offset(dotX, dotY), 5, fill);
    }
  }

  @override
  bool shouldRepaint(covariant LineWavePainter old) =>
      old.amplitudes != amplitudes ||
      old.progress != progress ||
      old.samplesPerSecond != samplesPerSecond ||
      old.displaySeconds != displaySeconds ||
      old.waveColor != waveColor ||
      old.showCenterLine != showCenterLine ||
      old.showMovingDot != showMovingDot ||
      old.heightScale != heightScale;
}

class KaraokeSubtitlePainter extends CustomPainter {
  final List<WordSegment> wordSegments;
  final int currentMs; // 再生位置[ms]
  final int displaySeconds; // 波形と同じ秒数

  // 視認性/調整ノブ
  final int lingerMs; // 終了後に残す時間
  final double minW; // 非アクティブ最小幅
  final double minWActive; // アクティブ最小幅
  final int futureLookaheadWords; // 未来の語を何語先まで出すか

  // 文字サイズ/色
  final double fontSizeActive;
  final double fontSizeGhost;
  final Color activeColor;
  final Color ghostBaseColor;
  final List<double> futureOpacities; // 未来の濃さ（距離1,2,3…）

  // ★ 追加：無音保持
  final bool holdDuringSilence; // 無音でも消さない
  final double silenceGhostOpacity; // 無音時に保持する直前語の濃さ
  final List<double> silenceFutureOpacities; // 無音時の未来濃さ

  KaraokeSubtitlePainter({
    required this.wordSegments,
    required this.currentMs,
    this.displaySeconds = 2,
    this.lingerMs = 240,
    this.minW = 64,
    this.minWActive = 110,
    this.futureLookaheadWords = 3,
    this.fontSizeActive = 21,
    this.fontSizeGhost = 19,
    this.activeColor = Colors.orange,
    this.ghostBaseColor = Colors.black87,
    this.futureOpacities = const [0.85, 0.70, 0.55],
    this.holdDuringSilence = true,
    this.silenceGhostOpacity = 0.70, // ← 無音でも“直前語”はこれで残す
    this.silenceFutureOpacities = const [0.80, 0.65, 0.50], // ← 無音時の未来も濃いめ
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wordSegments.isEmpty) return;

    final List<Shadow> _shadow = const [
      Shadow(blurRadius: 2, offset: Offset(0, 1), color: Color(0x55000000)),
    ];

    final windowMs = displaySeconds * 1000;
    final startMs = math.max(0, currentMs - windowMs ~/ 2);
    final endMs = startMs + windowMs;

    // 今のアクティブ語
    final activeIdx = wordSegments.indexWhere((w) {
      final ws = (w.start * 1000).toInt();
      final we = (w.end * 1000).toInt();
      return currentMs >= ws && currentMs <= we;
    });

    // ★ アンカー（無音時は直前語 or 直後語）を決定
    int anchorIdx = activeIdx;
    bool anchorIsPrev = true;
    if (anchorIdx == -1) {
      // 直前語
      int prev = -1;
      for (int i = 0; i < wordSegments.length; i++) {
        final we = (wordSegments[i].end * 1000).toInt();
        if (we <= currentMs)
          prev = i;
        else
          break;
      }
      // 直後語
      int next = -1;
      for (int i = math.max(0, prev); i < wordSegments.length; i++) {
        final ws = (wordSegments[i].start * 1000).toInt();
        if (ws >= currentMs) {
          next = i;
          break;
        }
      }
      if (prev != -1) {
        anchorIdx = prev;
        anchorIsPrev = true;
      } else if (next != -1) {
        anchorIdx = next;
        anchorIsPrev = false;
      }
    }

    for (int i = 0; i < wordSegments.length; i++) {
      final w = wordSegments[i];
      final ws = (w.start * 1000).toInt();
      final we = (w.end * 1000).toInt();

      if (we < startMs || ws > endMs) continue;

      double x0 = (ws - startMs) / windowMs * size.width;
      double x1 = (we - startMs) / windowMs * size.width;

      final isActive = (i == activeIdx);
      final isPastGhost =
          (!isActive && currentMs > we && currentMs <= we + lingerMs);

      // 未来濃さ
      double? futureAlpha;
      if (activeIdx != -1) {
        final dist = i - activeIdx; // 1=次、2=2語先…
        if (dist > 0 && dist <= futureLookaheadWords) {
          final idx = dist - 1;
          futureAlpha =
              (idx < futureOpacities.length ? futureOpacities[idx] : 0.55)
                  .clamp(0.0, 1.0);
        }
      }

      // ★ 無音時の保持（activeIdx == -1 かつ holdDuringSilence）
      bool showSilenceAnchor = false;
      double? silenceFutureAlpha;
      if (activeIdx == -1 && holdDuringSilence && anchorIdx != -1) {
        if (i == anchorIdx && anchorIsPrev) {
          // 直前語を“固定残像”で表示（lingerMsを超えても消さない）
          showSilenceAnchor = true;
        } else {
          // 直前語を基準に未来を出す（または先頭無音は直後語を基準に）
          final dist = (i - anchorIdx);
          if (anchorIsPrev && dist > 0 && dist <= futureLookaheadWords) {
            final idx = dist - 1;
            silenceFutureAlpha = (idx < silenceFutureOpacities.length
                    ? silenceFutureOpacities[idx]
                    : 0.5)
                .clamp(0.0, 1.0);
          }
          // 先頭側の無音（音声開始前）は anchor が直後語になるので、
          // i == anchorIdx（直後語）だけをうっすら見せたい場合はここに分岐を追加してもOK
        }
      }

      // 最小幅クランプ
      final need = isActive ? minWActive : minW;
      if ((x1 - x0) < need) {
        final mid = (x0 + x1) / 2;
        x0 = (mid - need / 2).clamp(0.0, size.width);
        x1 = (mid + need / 2).clamp(0.0, size.width);
      }

      // スタイル決定
      TextStyle? style;

      if (isActive) {
        style = TextStyle(
          fontSize: fontSizeActive,
          fontWeight: FontWeight.w600,
          color: activeColor,
          shadows: _shadow,
        );
      } else if (isPastGhost) {
        style = TextStyle(
          fontSize: fontSizeGhost,
          fontWeight: FontWeight.w500,
          color: ghostBaseColor.withOpacity(0.72),
          shadows: _shadow,
        );
      } else if (futureAlpha != null && futureAlpha > 0) {
        style = TextStyle(
          fontSize: fontSizeGhost,
          fontWeight: FontWeight.w500,
          color: ghostBaseColor.withOpacity(futureAlpha),
          shadows: _shadow,
        );
      } else if (showSilenceAnchor) {
        // ★ 無音保持：直前語をしっかり残す
        style = TextStyle(
          fontSize: fontSizeGhost,
          fontWeight: FontWeight.w600,
          color: ghostBaseColor.withOpacity(silenceGhostOpacity),
          shadows: _shadow,
        );
      } else if (silenceFutureAlpha != null && silenceFutureAlpha > 0) {
        // ★ 無音保持：直前語からの未来も表示
        style = TextStyle(
          fontSize: fontSizeGhost,
          fontWeight: FontWeight.w500,
          color: ghostBaseColor.withOpacity(silenceFutureAlpha),
          shadows: _shadow,
        );
      } else {
        continue; // 表示しない
      }

      final tp = TextPainter(
        text: TextSpan(text: w.word, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: (x1 - x0).clamp(0.0, size.width));

      final mid = (x0 + x1) / 2;
      final dy = (size.height - tp.height) / 2;
      tp.paint(canvas, Offset(mid - tp.width / 2, dy));
    }
  }

  @override
  bool shouldRepaint(covariant KaraokeSubtitlePainter old) =>
      old.currentMs != currentMs ||
      old.wordSegments != wordSegments ||
      old.displaySeconds != displaySeconds ||
      old.lingerMs != lingerMs ||
      old.minW != minW ||
      old.minWActive != minWActive ||
      old.futureLookaheadWords != futureLookaheadWords ||
      !_eq(old.futureOpacities, futureOpacities) ||
      old.fontSizeActive != fontSizeActive ||
      old.fontSizeGhost != fontSizeGhost ||
      old.activeColor != activeColor ||
      old.ghostBaseColor != ghostBaseColor ||
      old.holdDuringSilence != holdDuringSilence ||
      old.silenceGhostOpacity != silenceGhostOpacity ||
      !_eq(old.silenceFutureOpacities, silenceFutureOpacities);

  bool _eq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
