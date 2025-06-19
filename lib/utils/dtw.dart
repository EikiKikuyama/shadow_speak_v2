double calculateDTWDistance(List<double> seq1, List<double> seq2) {
  final int n = seq1.length;
  final int m = seq2.length;

  List<List<double>> dp = List.generate(
    n,
    (_) => List.filled(m, double.infinity),
  );

  dp[0][0] = (seq1[0] - seq2[0]).abs();

  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      double cost = (seq1[i] - seq2[j]).abs();

      if (i > 0 && j > 0) {
        dp[i][j] = cost +
            [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                .reduce((a, b) => a < b ? a : b);
      } else if (i > 0) {
        dp[i][j] = cost + dp[i - 1][j];
      } else if (j > 0) {
        dp[i][j] = cost + dp[i][j - 1];
      }
    }
  }

  return dp[n - 1][m - 1];
}

/// 0〜100点に変換（DTW距離が小さいほど高得点）
double calculateDTWScore(List<double> seq1, List<double> seq2) {
  double distance = calculateDTWDistance(seq1, seq2);

  // 正規化（距離が大きすぎるのを防ぐためにlogスケーリング）
  double normalized = distance / (seq1.length + seq2.length);
  double score = (1 / (1 + normalized)) * 100;

  return score.clamp(0, 100);
}
