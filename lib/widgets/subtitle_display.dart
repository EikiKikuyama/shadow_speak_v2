import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subtitle_segment.dart';
import '../models/word_segment.dart';

// 変更: 引数に selectedA / selectedB を追加
class SubtitleDisplay extends StatefulWidget {
  final Duration currentTime;
  final List<SubtitleSegment> allSubtitles;
  final Color highlightColor;
  final Color defaultColor;
  final void Function(WordSegment word)? onWordTap;
  final ABRepeatState abState;
  final Duration? abStart;
  final Duration? abEnd;
  final void Function(Duration start, Duration end)? onSelectSubtitle;

  // ★追加
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
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  Timer? _scrollCooldownTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        _markUserScrolling();
      }
    });
  }

  void _markUserScrolling() {
    _isUserScrolling = true;
    _scrollCooldownTimer?.cancel();
    _scrollCooldownTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isUserScrolling = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollCooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubtitleDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isUserScrolling) {
      final activeIndex = widget.allSubtitles.indexWhere((segment) =>
          widget.currentTime.inMilliseconds >= (segment.start * 1000).toInt() &&
          widget.currentTime.inMilliseconds < (segment.end * 1000).toInt());

      if (activeIndex != -1) {
        _scrollController.animateTo(
          activeIndex * 34.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ...省略...

  @override
  Widget build(BuildContext context) {
    final isSelecting = widget.abState == ABRepeatState.selectingA ||
        widget.abState == ABRepeatState.selectingB;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
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

              // build() 内の ListView.builder の itemBuilder から、単語描画部分のみ抜粋
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // セグメント全体をタップした時のフォールバック
                  if (widget.onSelectSubtitle != null &&
                      (widget.abState == ABRepeatState.selectingA ||
                          widget.abState == ABRepeatState.selectingB)) {
                    widget.onSelectSubtitle!(segmentStart, segmentEnd);
                  }
                },
                child: Container(
                  color: segmentBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: segment.words.map((word) {
                        final wordStart =
                            Duration(milliseconds: (word.start * 1000).toInt());
                        final wordEnd =
                            Duration(milliseconds: (word.end * 1000).toInt());

                        final isWordActive =
                            widget.currentTime.inMilliseconds >=
                                    wordStart.inMilliseconds &&
                                widget.currentTime.inMilliseconds <
                                    wordEnd.inMilliseconds;

                        // ★ A/B指定された単語かどうか（±10ms許容）
                        bool isAWord = false;
                        bool isBWord = false;
                        const tolMs = 10;
                        if (widget.selectedA != null) {
                          isAWord = (wordStart.inMilliseconds -
                                      widget.selectedA!.inMilliseconds)
                                  .abs() <=
                              tolMs;
                        }
                        if (widget.selectedB != null) {
                          isBWord = (wordEnd.inMilliseconds -
                                      widget.selectedB!.inMilliseconds)
                                  .abs() <=
                              tolMs;
                        }

                        Color color;
                        FontWeight weight = FontWeight.normal;

                        if (isAWord) {
                          color = Colors.red;
                          weight = FontWeight.bold;
                        } else if (isBWord) {
                          color = Colors.orange;
                          weight = FontWeight.bold;
                        } else if (isWordActive) {
                          color = widget.highlightColor;
                          weight = FontWeight.bold;
                        } else {
                          color = widget.defaultColor;
                        }

                        return WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () {
                              // ★ 単語タップを外へ通知（A/B確定に使う）
                              if (widget.onWordTap != null) {
                                widget.onWordTap!(word);
                              }
                            },
                            child: Text(
                              '${word.word} ',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: color,
                                  fontWeight: weight),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 必要：ABRepeatStateのenumをどこかに定義しておく
enum ABRepeatState {
  idle,
  selectingA,
  selectingB,
  ready,
}
