import 'package:flutter/material.dart';

class ABRepeatControls extends StatelessWidget {
  final String aTime;
  final String bTime;
  final VoidCallback onSetA; // AB開始（selectingAへ）
  final VoidCallback onSetB; // 使わない（将来用）
  final VoidCallback onReset; // 解除

  const ABRepeatControls({
    super.key,
    required this.aTime,
    required this.bTime,
    required this.onSetA,
    required this.onSetB,
    required this.onReset,
  });

  bool get isASet => aTime != "--";
  bool get isBSet => bTime != "--";

  @override
  Widget build(BuildContext context) {
    // ラベルと動作：A/B未設定なら「ABリピート」→ onSetA、どちらか設定済みなら「AB解除」→ onReset
    final bool hasAny = isASet || isBSet;
    final String label = hasAny ? "AB解除" : "ABリピート";
    final VoidCallback onPressed = hasAny ? onReset : onSetA;
    final Color? btnColor = hasAny ? Colors.red : null;

    // 補助テキスト（任意）：状態に応じてガイド表示
    String? caption;
    if (!isASet && !isBSet) {
      caption = "押した後、本文をタップしてA地点を選択";
    } else if (isASet && !isBSet) {
      caption = "本文をタップしてB地点を選択（長押しで解除）";
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          onLongPress: onReset, // いつでも長押し解除
          style: ElevatedButton.styleFrom(backgroundColor: btnColor),
          child: Text(label),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
