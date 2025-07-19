import 'dart:ui';

extension ColorToARGB32 on Color {
  /// Converts the Color to a 32-bit ARGB integer
  int toARGB32() {
    return (a.toInt() << 24) | (r.toInt() << 16) | (g.toInt() << 8) | b.toInt();
  }
}
