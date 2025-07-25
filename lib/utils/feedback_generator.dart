// lib/utils/feedback_generator.dart

String generatePronunciationFeedback(double whisperScore) {
  if (whisperScore >= 90) {
    return 'ほとんどの単語がしっかりと伝わっています。非常に良い発音です！';
  } else if (whisperScore >= 70) {
    return 'だいたいの単語は伝わっていますが、一部不明瞭な箇所があります。丁寧に発音しましょう。';
  } else {
    return 'ほとんどの単語が聞き取りづらいです。ゆっくりでいいので、一つひとつの単語をはっきりと発音していきましょう。';
  }
}

String generateProsodyFeedback(double prosodyScore) {
  if (prosodyScore >= 90) {
    return '抑揚がとても自然です。ネイティブのような話し方ができています！';
  } else if (prosodyScore >= 70) {
    return '安定していますが、抑揚が平坦に感じられる部分があります。特に破裂音などに注意して練習しましょう。';
  } else {
    return '全体的に平坦に聞こえます。強弱やリズムを意識して読むようにしてみましょう。';
  }
}
