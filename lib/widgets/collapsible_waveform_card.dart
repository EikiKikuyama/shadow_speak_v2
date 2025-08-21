// lib/widgets/collapsible_waveform_card.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 折りたたみ可能なカード（波形比較用）
/// - ヘッダにはタイトル＋凡例（青=見本 / 赤=あなた）
/// - body（child）は自由：静止画像でも、Stackで重ね描画でもOK
/// - prefsKey を指定すると開閉状態を永続化
class CollapsibleWaveformCard extends StatefulWidget {
  const CollapsibleWaveformCard({
    super.key,
    required this.child,
    this.title = '波形表示（見本: 青・あなた: 赤）',
    this.legend,
    this.initiallyExpanded = false,
    this.prefsKey,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(12),
    this.duration = const Duration(milliseconds: 220),
    this.onChanged,
  });

  final Widget child;
  final String title;
  final Widget? legend;
  final bool initiallyExpanded;
  final String? prefsKey;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Duration duration;
  final void Function(bool expanded)? onChanged;

  @override
  State<CollapsibleWaveformCard> createState() =>
      _CollapsibleWaveformCardState();
}

class _CollapsibleWaveformCardState extends State<CollapsibleWaveformCard>
    with TickerProviderStateMixin {
  bool? _expanded; // null の間は初期化中

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (widget.prefsKey == null) {
      setState(() => _expanded = widget.initiallyExpanded);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(widget.prefsKey!);
    setState(() => _expanded = saved ?? widget.initiallyExpanded);
  }

  Future<void> _persist(bool v) async {
    if (widget.prefsKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefsKey!, v);
  }

  void _toggle() {
    final next = !(_expanded ?? widget.initiallyExpanded);
    setState(() => _expanded = next);
    widget.onChanged?.call(next);
    _persist(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.backgroundColor ??
        (isDark ? Colors.white : Colors.white); // このカードは常に白ベースでOK
    final border = widget.borderColor ?? Colors.black12;

    // 初期化中はプレースホルダ（高さ0）
    final expanded = _expanded ?? false;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ヘッダ
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  // タイトル
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 凡例（デフォルト）
                  widget.legend ?? const _DefaultLegend(),
                  const SizedBox(width: 8),
                  // 開閉アイコン
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0, // ▼ / ▲
                    duration: widget.duration,
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),

          // 本文（開閉）
          AnimatedSize(
            duration: widget.duration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: expanded
                ? Padding(
                    padding: widget.padding,
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DefaultLegend extends StatelessWidget {
  const _DefaultLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Dot(color: Colors.blueAccent, label: '見本'),
        SizedBox(width: 8),
        _Dot(color: Colors.redAccent, label: 'あなた'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
