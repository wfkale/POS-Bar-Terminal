/// Shared viewport breakpoints for floor + till PWAs.
class PosBreakpoints {
  static const compact = 700.0;
  static const medium = 900.0;

  static bool isCompact(double width) => width < compact;

  static bool isMedium(double width) => width >= compact && width < medium;

  static bool isWide(double width) => width >= medium;

  /// Side cart width when order screen is side-by-side.
  static double cartWidth(double width) {
    if (isWide(width)) return (width * 0.32).clamp(260.0, 340.0);
    if (isMedium(width)) return (width * 0.34).clamp(220.0, 280.0);
    return width;
  }

  /// Staff sign-in grid columns.
  static int signInColumns(double width) {
    if (width < 500) return 2;
    if (width < 800) return 3;
    return 4;
  }

  /// Floor home action grid columns.
  static int homeColumns(double width) {
    if (width < 600) return 2;
    return 3;
  }
}
