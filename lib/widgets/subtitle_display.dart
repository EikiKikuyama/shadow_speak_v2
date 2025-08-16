import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ScrollDirection
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

class SubtitleDisplay extends StatefulWidget {
  final Duration currentTime;
  final List<SubtitleSegment> allSubtitles;
  final Color highlightColor;
  final Color defaultColor;
  final void Function(WordSegment word)? onWordTap;

  // AB関連
  final ABRepeatState abState;
  final Duration? abStart;
  final Duration? abEnd;
  final void Function(Duration start, Duration end)? onSelectSubtitle;

  // A/B が単語境界に合っている時の表示用
  final Duration? selectedA;
  final Duration? selectedB;

  const SubtitleDisplay({
    super.key,
    required this.currentTime,
    required this.allSubtitles,
    this.highlightColor = Colors.yellow,
    this.defaultColor = Colors.white,
    this.onWordTap,
    required this.abState,
    this.abStart,
    this.abEnd,
    this.onSelectSubtitle,
    this.selectedA,
    this.selectedB,
  });

  @override
  State<SubtitleDisplay> createState() => _SubtitleDisplayState();
}

class _SubtitleDisplayState extends State<SubtitleDisplay> {
  final _scrollController = ScrollController();

  // 実測スクロールに必要なキー
  final _listKey = GlobalKey();
  List<GlobalKey> _itemKeys = []; // ← late をやめて空で初期化

  int _activeIndex = -1;
  bool _didInitialAlign = false;
  bool _userDragging = false;
  DateTime _lastAuto = DateTime.fromMillisecondsSinceEpoch(0);

  // 行数に合わせてキーを確保
  void _ensureItemKeys() {
    final need = widget.allSubtitles.length;
    if (_itemKeys.length != need) {
      _itemKeys = List.generate(need, (_) => GlobalKey());
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureItemKeys();
  }

  @override
  void didUpdateWidget(covariant SubtitleDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allSubtitles.length != widget.allSubtitles.length) {
      _ensureItemKeys();
    }
    _updateActiveAndMaybeScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _findActiveIndex(Duration t) {
    final ms = t.inMilliseconds;
    for (int i = 0; i < widget.allSubtitles.length; i++) {
      final seg = widget.allSubtitles[i];
      final s = (seg.start * 1000).round();
      final e = (seg.end * 1000).round();
      if (ms >= s && ms <= e) return i;
    }
    return -1;
  }

  // 常にゆっくり下へ追従（2〜3行目あたりに居続ける）
  void _updateActiveAndMaybeScroll() {
    final idx = _findActiveIndex(widget.currentTime);
    if (idx == _activeIndex) return;
    _activeIndex = idx;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _activeIndex < 0) return;
      if (_userDragging) return;

      final listCtx = _listKey.currentContext;
      final itemCtx = _itemKeys[_activeIndex].currentContext;
      if (listCtx == null || itemCtx == null) return;

      final listBox = listCtx.findRenderObject() as RenderBox?;
      final itemBox = itemCtx.findRenderObject() as RenderBox?;
      if (listBox == null || itemBox == null) return;

      // ビューポート内の位置
      final itemTopVP =
          itemBox.localToGlobal(Offset.zero, ancestor: listBox).dy;
      final itemH = itemBox.size.height;
      final viewH = listBox.size.height;

      // アクティブ行の中心をビューポートの 28% 位置に合わせる
      const alignFrac = 0.28; // 0=最上, 0.5=中央
      final itemCenterAbs = _scrollController.offset + itemTopVP + itemH / 2;
      final targetOffsetRaw = itemCenterAbs - alignFrac * viewH;

      double target = targetOffsetRaw.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      final dist = (target - _scrollController.offset).abs();

      if (!_didInitialAlign) {
        _scrollController.jumpTo(target); // 初回だけジャンプで合わせる
        _didInitialAlign = true;
        return;
      }

      final now = DateTime.now();
      final dt = now.difference(_lastAuto).inMilliseconds;
      _lastAuto = now;
      if (dist < 6 || dt < 120) return; // 微小移動・連打は無視

      final durMs = (120 + dist * 0.35).clamp(160, 420).toInt();
      _scrollController.animateTo(
        target,
        duration: Duration(milliseconds: durMs),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureItemKeys(); // Hot reload/レイアウト変化の安全網

    final isSelecting = widget.abState == ABRepeatState.selectingA ||
        widget.abState == ABRepeatState.selectingB;

    return SizedBox(
      height: 200,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          _userDragging = n.direction != ScrollDirection.idle;
          return false;
        },
        child: ListView.builder(
          key: _listKey,
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          physics: const ClampingScrollPhysics(),
          itemCount: widget.allSubtitles.length,
          itemBuilder: (context, index) {
            final segment = widget.allSubtitles[index];
            final segmentStart =
                Duration(milliseconds: (segment.start * 1000).toInt());
            final segmentEnd =
                Duration(milliseconds: (segment.end * 1000).toInt());

            final inAB = widget.abStart != null &&
                widget.abEnd != null &&
                segmentEnd >= widget.abStart! &&
                segmentStart <= widget.abEnd!;

            final isDarkening = isSelecting;
            final segmentBackgroundColor = isDarkening
                ? (inAB ? Colors.transparent : Colors.black.withOpacity(0.5))
                : Colors.transparent;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.onSelectSubtitle != null &&
                    (widget.abState == ABRepeatState.selectingA ||
                        widget.abState == ABRepeatState.selectingB)) {
                  widget.onSelectSubtitle!(segmentStart, segmentEnd);
                }
              },
              child: Container(
                key: _itemKeys[index],
                color: segmentBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RichText(
                  textAlign: TextAlign.center,
                  // 行高を固定して折り返しの高さブレを抑制
                  strutStyle: const StrutStyle(
                    forceStrutHeight: true,
                    height: 1.35,
                    leading: 0,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  text: TextSpan(
                    children: segment.words.map((word) {
                      final ws =
                          Duration(milliseconds: (word.start * 1000).toInt());
                      final we =
                          Duration(milliseconds: (word.end * 1000).toInt());

                      final isWordActive = widget.currentTime.inMilliseconds >=
                              ws.inMilliseconds &&
                          widget.currentTime.inMilliseconds < we.inMilliseconds;

                      // A/B マーカー（±10ms許容）
                      const tolMs = 10;
                      final isAWord = widget.selectedA != null &&
                          (ws.inMilliseconds - widget.selectedA!.inMilliseconds)
                                  .abs() <=
                              tolMs;
                      final isBWord = widget.selectedB != null &&
                          (we.inMilliseconds - widget.selectedB!.inMilliseconds)
                                  .abs() <=
                              tolMs;

                      // 幅が変わらないよう常に同じウェイト
                      final base = const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      );

                      TextStyle style;
                      if (isAWord) {
                        style = base.copyWith(color: Colors.red);
                      } else if (isBWord) {
                        style = base.copyWith(color: Colors.orange);
                      } else if (isWordActive) {
                        // ★ 下線ナシ。色だけで強調
                        style = base.copyWith(color: widget.highlightColor);
                      } else {
                        style = base.copyWith(color: widget.defaultColor);
                      }

                      return WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => widget.onWordTap?.call(word),
                          child: Text('${word.word} ', style: style),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 必要：ABリピート状態
enum ABRepeatState { idle, selectingA, selectingB, ready }
