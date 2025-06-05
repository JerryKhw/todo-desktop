extension DoubleExtension on double {
  double toFigmaLineHeight(double fontSize) {
    return this / fontSize;
  }
}

extension IntExtension on int {
  double toFigmaLineHeight(int fontSize) {
    return this / fontSize;
  }
}
