// lib/utils/scoring_utils.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ===== プロソディ（波形類似度：0..100） =====
/// a,b は 0..1 の 200fps 系列想定（長さ違ってOK）
double prosodyScoreFromSeries(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;

  List<double> _znorm(List<double> x) {
    final m = x.reduce((p, c) => p + c) / x.length;
    double v = 0.0;
    for (final xi in x) v += (xi - m) * (xi - m);
    v = (v / x.length).clamp(1e-12, double.infinity);
    final s = math.sqrt(v);
    return x.map((xi) => (xi - m) / s).toList();
  }

  final x = _znorm(a);
  final y = _znorm(b);

  final d = _dtwDistance(x, y);
  // d を 0..1 に押し込み → 100 点化（甘辛は係数で調整）
  final n = (x.length + y.length) / 2.0;
  final norm = d / (n * 0.9); // ← 0.9→0.8で少し甘く、1.0で辛く
  final sim = 1.0 / (1.0 + norm); // 0..1（距離小→類似大）
  final score = (100.0 * math.pow(sim, 1.2)).clamp(0.0, 100.0);
  return score.toDouble();
}

double _dtwDistance(List<double> x, List<double> y) {
  final n = x.length, m = y.length;
  const big = 1e18;
  final dp = List.generate(n + 1, (_) => List<double>.filled(m + 1, big));
  dp[0][0] = 0.0;
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      final cost = (x[i - 1] - y[j - 1]).abs();
      final prev =
          math.min(dp[i - 1][j], math.min(dp[i][j - 1], dp[i - 1][j - 1]));
      dp[i][j] = cost + prev;
    }
  }
  return dp[n][m];
}

/// ===== 単語認識スコア（0..100） =====
double wordAccuracyScore(String reference, String hyp) {
  final r = _tokenize(reference);
  final h = _tokenize(hyp);
  if (r.isEmpty) return 0.0;
  final ops = _levOps(r, h);
  int correct = 0;
  for (final op in ops) {
    if (op.type == _OpType.equal) correct++;
  }
  return (100.0 * correct / r.length).clamp(0.0, 100.0).toDouble();
}

/// エイリアス（既存呼び名に合わせたい場合）
double whisperScoreFromTexts(String reference, String hyp) =>
    wordAccuracyScore(reference, hyp);

/// ===== Diff 表示用 TextSpan を作る =====
List<TextSpan> buildDiffSpans(
  String reference,
  String hyp, {
  TextStyle? ok, // 一致
  TextStyle? subStyle, // 置換（誤り）
  TextStyle? delStyle, // 削除（言い漏れ）
  TextStyle? insStyle, // 挿入（余計）
}) {
  final baseOk = ok ?? const TextStyle(color: Colors.black87);
  final baseSub = subStyle ??
      const TextStyle(color: Colors.red, decoration: TextDecoration.underline);
  final baseDel = delStyle ??
      const TextStyle(
          color: Colors.grey, decoration: TextDecoration.lineThrough);
  final baseIns = insStyle ??
      const TextStyle(
          color: Colors.orange, decoration: TextDecoration.underline);

  final ops = _align(reference, hyp);
  final spans = <TextSpan>[];
  for (final op in ops) {
    switch (op.type) {
      case _OpType.equal:
        spans.add(TextSpan(text: '${op.ref} ', style: baseOk));
        break;
      case _OpType.replace:
        spans.add(TextSpan(text: '${op.hyp ?? op.ref ?? ''} ', style: baseSub));
        break;
      case _OpType.delete:
        spans.add(TextSpan(text: '${op.ref} ', style: baseDel));
        break;
      case _OpType.insert:
        spans.add(TextSpan(text: '${op.hyp} ', style: baseIns));
        break;
    }
  }
  return spans;
}

/// ===== 内部：ワード整列 =====
enum _OpType { equal, replace, delete, insert }

class _Op {
  final _OpType type;
  final String? ref;
  final String? hyp;
  _Op(this.type, {this.ref, this.hyp});
}

List<_Op> _align(String reference, String hyp) {
  final r = _tokenize(reference);
  final h = _tokenize(hyp);
  return _levOps(r, h);
}

List<String> _tokenize(String s) {
  final lower = s.toLowerCase();
  final out = <String>[];
  final buf = StringBuffer();
  for (int i = 0; i < lower.length; i++) {
    final c = lower.codeUnitAt(i);
    final az = (c >= 97 && c <= 122);
    if (az) {
      buf.writeCharCode(c);
    } else {
      if (buf.isNotEmpty) {
        out.add(buf.toString());
        buf.clear();
      }
    }
  }
  if (buf.isNotEmpty) out.add(buf.toString());
  return out;
}

List<_Op> _levOps(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (int i = 0; i <= n; i++) dp[i][0] = i;
  for (int j = 0; j <= m; j++) dp[0][j] = j;
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
      dp[i][j] = math.min(math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost);
    }
  }
  final ops = <_Op>[];
  int i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        dp[i][j] == dp[i - 1][j - 1] &&
        a[i - 1] == b[j - 1]) {
      ops.add(_Op(_OpType.equal, ref: a[i - 1], hyp: b[j - 1]));
      i--;
      j--;
    } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
      ops.add(_Op(_OpType.replace, ref: a[i - 1], hyp: b[j - 1]));
      i--;
      j--;
    } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
      ops.add(_Op(_OpType.delete, ref: a[i - 1]));
      i--;
    } else {
      ops.add(_Op(_OpType.insert, hyp: b[j - 1]));
      j--;
    }
  }
  return ops.reversed.toList();
}

// ====== 自動フィードバック（抑揚） ======
String buildProsodyFeedback(double score, List<double> userSeries) {
  if (userSeries.isEmpty) {
    return '録音波形がありません。もう一度録音してみてください。';
  }

  // 基本メトリクス
  double _percentile(List<double> xs, double p) {
    final x = [...xs]..sort();
    final i = (p * (x.length - 1)).clamp(0, x.length - 1).toInt();
    return x[i];
  }

  final nonzero = userSeries.where((v) => v > 0).toList();
  final p10 = _percentile(nonzero.isEmpty ? [0] : nonzero, 0.10);
  final p90 = _percentile(nonzero.isEmpty ? [0] : nonzero, 0.90);
  final dynamicRange = (p90 - p10).clamp(0.0, 1.0); // 強弱の幅
  final gate = 0.05;
  final voicedRatio =
      userSeries.where((v) => v > gate).length / userSeries.length;

  // 立ち上がり回数（フレーズ数っぽい指標）
  int onsets = 0;
  bool up = false;
  int cool = 0;
  for (final v in userSeries) {
    if (cool > 0) {
      cool--;
      continue;
    }
    if (!up && v > gate) {
      onsets++;
      up = true;
      cool = 6;
    } // 30ms デバウンス
    if (up && v <= gate) up = false;
  }

  final b = StringBuffer();

  // スコアベースの大枠コメント
  if (score >= 85) {
    b.writeln('抑揚はとても良好です。重要語が適切に強調され、聞き取りやすいリズムです。');
  } else if (score >= 70) {
    b.writeln('おおむね良好ですが、語尾がやや平坦になりがちです。フレーズ末を少し弱めてメリハリを付けましょう。');
  } else if (score >= 50) {
    b.writeln('強弱の波が小さい傾向です。重要語をやや強めに、機能語は軽めに読むとメリハリが出ます。');
  } else {
    b.writeln('全体的に平坦です。ストレス位置（内容語）をはっきり強め、間や息継ぎで区切りを作ってみましょう。');
  }

  // 追加の具体アドバイス（簡易ヒューリスティック）
  if (dynamicRange < 0.20) {
    b.writeln('・強弱の幅が小さめです：強く読みたい語で音量/高さを+20〜30%上げる意識を。');
  } else if (dynamicRange > 0.50) {
    b.writeln('・ダイナミクスは十分あります。この調子で安定さも意識できるとさらに◎。');
  }

  if (voicedRatio < 0.25) {
    b.writeln('・無音（間）が長めです：テンポを少し上げて、語と語のつながりを作ると自然です。');
  } else if (voicedRatio > 0.85) {
    b.writeln('・間が少なめです：文の区切れで短い間(0.2〜0.3秒)を入れると聞きやすくなります。');
  }

  if (onsets <= 3) {
    b.writeln('・フレーズの分割が少ないかも：カンマや接続詞で軽く区切って起伏を付けましょう。');
  }

  return b.toString().trim();
}

// ====== 自動フィードバック（発音/語の認識） ======
String buildPronunciationFeedback(
  double whisperScore,
  String reference,
  String hyp,
) {
  final ops = _align(reference, hyp);
  final replaced = <String>[];
  final deleted = <String>[];
  final inserted = <String>[];

  for (final op in ops) {
    switch (op.type) {
      case _OpType.replace:
        if (op.hyp != null) replaced.add(op.hyp!);
        break;
      case _OpType.delete:
        if (op.ref != null) deleted.add(op.ref!);
        break;
      case _OpType.insert:
        if (op.hyp != null) inserted.add(op.hyp!);
        break;
      case _OpType.equal:
        break;
    }
  }

  // 関数語が多く落ちているかをざっくり検出
  final func = {
    'a',
    'an',
    'the',
    'to',
    'of',
    'and',
    'or',
    'for',
    'in',
    'on',
    'at'
  };
  final droppedFunc = deleted.where(func.contains).length;

  final b = StringBuffer();

  if (whisperScore >= 90) {
    b.writeln('認識は非常に良好です。細部の明瞭さを高めるとさらに安定します。');
  } else if (whisperScore >= 80) {
    b.writeln('良好です。語頭・語尾の子音をはっきり出すと取りこぼしが減ります。');
  } else if (whisperScore >= 60) {
    b.writeln('中程度の精度です。以下の語の発音を意識して練習しましょう。');
  } else {
    b.writeln('誤認識が多めです。短いフレーズに分け、母音の長さと子音の開放をはっきり練習しましょう。');
  }

  List<String> _pick(List<String> list, int n) =>
      (list.length <= n) ? list : list.sublist(0, n);

  final examples = <String>[];
  if (replaced.isNotEmpty) examples.add('置換: ${_pick(replaced, 4).join(", ")}');
  if (deleted.isNotEmpty) examples.add('脱落: ${_pick(deleted, 4).join(", ")}');
  if (inserted.isNotEmpty) examples.add('余分: ${_pick(inserted, 4).join(", ")}');
  if (examples.isNotEmpty) b.writeln('例）${examples.join(' / ')}');

  if (droppedFunc >= 3) {
    b.writeln('・「the / a / to」など機能語の脱落が目立ちます。弱く短くでも**必ず通す**意識を。');
  }

  // 共通の発音TIP（軽め）
  b.writeln('・/θ ð/（th）と /r l/ の区別、母音の長さ、語末子音の開放を意識すると精度が上がります。');

  return b.toString().trim();
}
