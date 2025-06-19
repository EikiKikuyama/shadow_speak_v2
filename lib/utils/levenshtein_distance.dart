int levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<List<int>> dp = List.generate(
    s.length + 1,
    (_) => List.filled(t.length + 1, 0),
  );

  for (int i = 0; i <= s.length; i++) dp[i][0] = i;
  for (int j = 0; j <= t.length; j++) dp[0][j] = j;

  for (int i = 1; i <= s.length; i++) {
    for (int j = 1; j <= t.length; j++) {
      int cost = s[i - 1] == t[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1, // 削除
        dp[i][j - 1] + 1, // 追加
        dp[i - 1][j - 1] + cost // 置換
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[s.length][t.length];
}

double calculateAccuracy(String correct, String result) {
  int maxLen = correct.length > result.length ? correct.length : result.length;
  int distance = levenshtein(correct, result);
  return ((maxLen - distance) / maxLen * 100).clamp(0, 100);
}

enum DiffType { equal, insert, delete }

class DiffChar {
  final String char;
  final DiffType type;

  DiffChar(this.char, this.type);
}

List<DiffChar> levenshteinDiff(String a, String b) {
  final m = a.length;
  final n = b.length;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

  // DPテーブル作成
  for (int i = 0; i <= m; i++) dp[i][0] = i;
  for (int j = 0; j <= n; j++) dp[0][j] = j;

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 +
            [
              dp[i - 1][j], // 削除
              dp[i][j - 1], // 挿入
              dp[i - 1][j - 1], // 置換
            ].reduce((a, b) => a < b ? a : b);
      }
    }
  }

  // バックトラックで差分を復元
  int i = m, j = n;
  final result = <DiffChar>[];

  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
      result.insert(0, DiffChar(a[i - 1], DiffType.equal));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] <= dp[i - 1][j])) {
      result.insert(0, DiffChar(b[j - 1], DiffType.insert));
      j--;
    } else if (i > 0 && (j == 0 || dp[i][j - 1] > dp[i - 1][j])) {
      result.insert(0, DiffChar(a[i - 1], DiffType.delete));
      i--;
    }
  }

  return result;
}
