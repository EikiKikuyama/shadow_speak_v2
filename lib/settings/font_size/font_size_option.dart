enum FontSizeOption { small, medium, large }

extension FontSizeExtension on FontSizeOption {
  double get scaleFactor {
    switch (this) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.medium:
        return 1.0;
      case FontSizeOption.large:
        return 1.25;
    }
  }

  String get displayName {
    switch (this) {
      case FontSizeOption.small:
        return '小';
      case FontSizeOption.medium:
        return '中';
      case FontSizeOption.large:
        return '大';
    }
  }
}
