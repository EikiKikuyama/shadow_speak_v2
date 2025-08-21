import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shadow_speak_v2/models/word_segment.dart';

class LineWavePainter extends CustomPainter {
  final List<double> amplitudes; // 0..1 （等間隔, 推奨200サンプル/秒）
  final double progress; // 0..1 再生位置（録音/サンプル用）
  final int samplesPerSecond; // 200 = 5ms刻み
  final int displaySeconds; // 可視窓秒数
  final Color waveColor;
  final bool showCenterLine; // 固定ライン
  final bool showMovingDot; // 現在位置ドット
  final double heightScale; // 0.0..1.0
  final double verticalPadding; // 下余白（ゼロ線位置）
  final bool growFromLeft; // 左から伸ばす（RT用）
  final bool centerLatest; // ★ 追加：最新点を中央に固定（RT用）

  LineWavePainter({
    required this.amplitudes,
    required this.progress,
    this.samplesPerSecond = 200,
    this.displaySeconds = 3,
    this.waveColor = Colors.blueAccent,
    this.showCenterLine = false,
    this.showMovingDot = true,
    this.heightScale = 0.95,
    required double maxAmplitude, // 互換のため残す（未使用）
    this.verticalPadding = 10.0,
    this.growFromLeft = false,
    this.centerLatest = false, // ★ デフォルトOFF
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final total = amplitudes.length;
    final dispRaw = samplesPerSecond * displaySeconds;
    final disp = math.min(dispRaw, total + dispRaw); // 右側のゼロ領域も描けるよう余裕持たせ
    final h = (size.height - verticalPadding * 2.0).clamp(0.0, double.infinity);
    if (h <= 0) return;
    final baseY = size.height - verticalPadding;

    // 範囲外は0を返すヘルパ
    double aAt(int i) {
      if (i < 0 || i >= total) return 0.0;
      final v = amplitudes[i];
      return v.isFinite ? v.clamp(0.0, 1.0) : 0.0;
    }

    // 可視範囲とドット位置を決める
    int start, end, cursorIdx;

    if (growFromLeft && centerLatest) {
      // ★ RT：最新サンプルを中央に固定（埋まるまでは左から伸びる）
      final half = disp ~/ 2;
      cursorIdx = total - 1;
      if (total <= half) {
        // まだ窓を埋めない：左から伸びる
        start = 0;
        end = total;
      } else {
        // 窓を埋めた：最新を中央に置く（右側はゼロ線で埋まる）
        start = cursorIdx - half;
        end = start + disp;
      }
    } else if (growFromLeft) {
      // 旧RT：常に右端に最新
      if (total <= disp) {
        start = 0;
        end = total;
      } else {
        start = total - disp;
        end = total;
      }
      cursorIdx = (end - 1).clamp(0, total - 1);
    } else {
      // 従来：progress中心スクロール（サンプル再生用）
      final safeProg = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
      final centerIdx = (safeProg * (total - 1)).round();
      final half = disp ~/ 2;
      start = math.max(0, math.min(centerIdx - half, total - disp));
      end = start + disp;
      cursorIdx = centerIdx.clamp(0, total - 1);
    }

    final span = math.max(1, end - start);
    final unitW = span > 1 ? size.width / (span - 1) : size.width;

    // 波形パス
    final path = Path();
    for (int i = start; i < end; i++) {
      final x = (i - start) * unitW;
      final y = baseY - (aAt(i) * h * heightScale);
      if (i == start) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final wavePaint = Paint()
      ..isAntiAlias = true
      ..color = waveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, wavePaint);

    // 中央ライン（任意）
    if (showCenterLine) {
      final cx = size.width / 2;
      final glow = Paint()
        // ignore: deprecated_member_use
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
      final dotX = (cursorIdx - start) * unitW;
      final dotY = baseY - (aAt(cursorIdx) * h * heightScale);
      // ignore: deprecated_member_use
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
      old.heightScale != heightScale ||
      old.verticalPadding != verticalPadding ||
      old.growFromLeft != growFromLeft ||
      old.centerLatest != centerLatest;
}

// =====（下は字幕ペインタ：そのまま）=====
class KaraokeSubtitlePainter extends CustomPainter {
  final List<WordSegment> wordSegments;
  final int currentMs; // 再生位置[ms]
  final int displaySeconds;

  // 視認性/調整ノブ
  final int lingerMs;
  final double minW;
  final double minWActive;
  final int futureLookaheadWords;

  // 文字サイズ/色
  final double fontSizeActive;
  final double fontSizeGhost;
  final Color activeColor;
  final Color ghostBaseColor;
  final List<double> futureOpacities;

  // 無音保持
  final bool holdDuringSilence;
  final double silenceGhostOpacity;
  final List<double> silenceFutureOpacities;
  final double verticalPadding;

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
    this.silenceGhostOpacity = 0.70,
    this.silenceFutureOpacities = const [0.80, 0.65, 0.50],
    this.verticalPadding = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wordSegments.isEmpty) return;

    final List<Shadow> shadow = const [
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

    // 無音時のアンカー
    int anchorIdx = activeIdx;
    bool anchorIsPrev = true;
    if (anchorIdx == -1) {
      int prev = -1;
      for (int i = 0; i < wordSegments.length; i++) {
        final we = (wordSegments[i].end * 1000).toInt();
        if (we <= currentMs)
          prev = i;
        else
          break;
      }
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

      double? futureAlpha;
      if (activeIdx != -1) {
        final dist = i - activeIdx;
        if (dist > 0 && dist <= futureLookaheadWords) {
          final idx = dist - 1;
          futureAlpha =
              (idx < futureOpacities.length ? futureOpacities[idx] : 0.55)
                  .clamp(0.0, 1.0);
        }
      }

      bool showSilenceAnchor = false;
      double? silenceFutureAlpha;
      if (activeIdx == -1 && holdDuringSilence && anchorIdx != -1) {
        if (i == anchorIdx && anchorIsPrev) {
          showSilenceAnchor = true;
        } else {
          final dist = (i - anchorIdx);
          if (anchorIsPrev && dist > 0 && dist <= futureLookaheadWords) {
            final idx = dist - 1;
            silenceFutureAlpha = (idx < silenceFutureOpacities.length
                    ? silenceFutureOpacities[idx]
                    : 0.5)
                .clamp(0.0, 1.0);
          }
        }
      }

      // 最小幅クランプ
      final need = isActive ? minWActive : minW;
      if ((x1 - x0) < need) {
        final mid = (x0 + x1) / 2;
        x0 = (mid - need / 2).clamp(0.0, size.width);
        x1 = (mid + need / 2).clamp(0.0, size.width);
      }

      TextStyle? style;
      if (isActive) {
        style = TextStyle(
            fontSize: fontSizeActive,
            fontWeight: FontWeight.w600,
            color: activeColor,
            shadows: shadow);
      } else if (isPastGhost) {
        style = TextStyle(
            fontSize: fontSizeGhost,
            fontWeight: FontWeight.w500,
            // ignore: deprecated_member_use
            color: ghostBaseColor.withOpacity(0.72),
            shadows: shadow);
      } else if (futureAlpha != null && futureAlpha > 0) {
        style = TextStyle(
            fontSize: fontSizeGhost,
            fontWeight: FontWeight.w500,
            // ignore: deprecated_member_use
            color: ghostBaseColor.withOpacity(futureAlpha),
            shadows: shadow);
      } else if (showSilenceAnchor) {
        style = TextStyle(
            fontSize: fontSizeGhost,
            fontWeight: FontWeight.w600,
            // ignore: deprecated_member_use
            color: ghostBaseColor.withOpacity(silenceGhostOpacity),
            shadows: shadow);
      } else if (silenceFutureAlpha != null && silenceFutureAlpha > 0) {
        style = TextStyle(
            fontSize: fontSizeGhost,
            fontWeight: FontWeight.w500,
            // ignore: deprecated_member_use
            color: ghostBaseColor.withOpacity(silenceFutureAlpha),
            shadows: shadow);
      } else {
        continue;
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
      old.verticalPadding != verticalPadding ||
      !_eq(old.silenceFutureOpacities, silenceFutureOpacities);

  bool _eq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
