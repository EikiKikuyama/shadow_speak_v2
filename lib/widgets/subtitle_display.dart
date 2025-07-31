import 'dart:async';
import 'package:flutter/material.dart';

import '../models/subtitle_segment.dart';

class SubtitleDisplay extends StatefulWidget {
  final SubtitleSegment? currentSubtitle;
  final List<SubtitleSegment> allSubtitles;

  final Color highlightColor;
  final Color defaultColor;

  const SubtitleDisplay({
    Key? key,
    required this.currentSubtitle,
    required this.allSubtitles,
    this.highlightColor = Colors.yellow, // ← デフォルト値
    this.defaultColor = Colors.white, // ← デフォルト値
  }) : super(key: key);

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

    // ユーザーのスクロールを検出
    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        _markUserScrolling();
      }
    });
  }

  void _markUserScrolling() {
    _isUserScrolling = true;

    // 一定時間ユーザー操作がなければ、自動スクロールを再開
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

    // 自動スクロール（ユーザーが手動で操作していない時だけ）
    if (!_isUserScrolling &&
        widget.currentSubtitle != null &&
        widget.allSubtitles.contains(widget.currentSubtitle)) {
      final index = widget.allSubtitles.indexOf(widget.currentSubtitle!);
      _scrollController.animateTo(
        index * 34.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Scrollbar(
        thumbVisibility: true,
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.allSubtitles.length,
          itemBuilder: (context, index) {
            final segment = widget.allSubtitles[index];
            final isActive = segment == widget.currentSubtitle;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                segment.text,
                style: TextStyle(
                  height: 1.5,
                  fontSize: 20,
                  color: isActive ? widget.highlightColor : widget.defaultColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}
