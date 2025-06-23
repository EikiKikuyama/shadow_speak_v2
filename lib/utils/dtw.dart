import 'dart:math';
import 'dart:isolate';

double calculateDTWDistance(List<double> seq1, List<double> seq2) {
  final int n = seq1.length;
  final int m = seq2.length;

  List<double> prev = List.filled(m, double.infinity);
  List<double> curr = List.filled(m, double.infinity);

  prev[0] = (seq1[0] - seq2[0]).abs();
  for (int j = 1; j < m; j++) {
    prev[j] = (seq1[0] - seq2[j]).abs() + prev[j - 1];
  }

  for (int i = 1; i < n; i++) {
    curr[0] = (seq1[i] - seq2[0]).abs() + prev[0];
    for (int j = 1; j < m; j++) {
      double cost = (seq1[i] - seq2[j]).abs();
      curr[j] = cost + min(prev[j - 1], min(curr[j - 1], prev[j]));
    }
    final temp = prev;
    prev = curr;
    curr = temp;
  }

  return prev[m - 1];
}

Future<double> calculateDTWDistanceInIsolate(
    List<double> seq1, List<double> seq2) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_dtwIsolate, [receivePort.sendPort, seq1, seq2]);

  return await receivePort.first as double;
}

void _dtwIsolate(List<dynamic> args) {
  final SendPort sendPort = args[0];
  final List<double> seq1 = args[1];
  final List<double> seq2 = args[2];

  final result = calculateDTWDistance(seq1, seq2);
  sendPort.send(result);
}

/// 0〜100点に変換（DTW距離が小さいほど高得点）
double calculateDTWScore(List<double> seq1, List<double> seq2) {
  double distance = calculateDTWDistance(seq1, seq2);

  // 正規化（距離が大きすぎるのを防ぐためにlogスケーリング）
  double normalized = distance / (seq1.length + seq2.length);
  double score = (1 / (1 + normalized)) * 100;

  return score.clamp(0, 100);
}

List<List<int>> calculateDTWPath(List<double> seq1, List<double> seq2) {
  final int n = seq1.length;
  final int m = seq2.length;

  final List<List<double>> dp =
      List.generate(n, (_) => List.filled(m, double.infinity));
  final List<List<List<List<int>>>> path =
      List.generate(n, (_) => List.generate(m, (_) => []));

  dp[0][0] = (seq1[0] - seq2[0]).abs();
  path[0][0] = [
    [0, 0]
  ]; // ✅ ←ここ重要！

  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      if (i == 0 && j == 0) continue;

      final cost = (seq1[i] - seq2[j]).abs();

      double minPrev = double.infinity;
      List<int>? bestStep;

      if (i > 0 && dp[i - 1][j] < minPrev) {
        minPrev = dp[i - 1][j];
        bestStep = [i - 1, j];
      }
      if (j > 0 && dp[i][j - 1] < minPrev) {
        minPrev = dp[i][j - 1];
        bestStep = [i, j - 1];
      }
      if (i > 0 && j > 0 && dp[i - 1][j - 1] < minPrev) {
        minPrev = dp[i - 1][j - 1];
        bestStep = [i - 1, j - 1];
      }

      if (bestStep != null) {
        dp[i][j] = cost + minPrev;
        path[i][j] = List.from(path[bestStep[0]][bestStep[1]])..add([i, j]);
      }
    }
  }

  return path[n - 1][m - 1]; // ✅ ここもOK！
}
