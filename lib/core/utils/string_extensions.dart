/// Dart extension methods on [String] used across the UI.
extension StringExtensions on String {
  /// Returns the first N characters as initials (e.g. "John Doe" → "JD").
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Capitalises the first character only.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates to [maxLength] chars, appending '…' when trimmed.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

/// Null-safe extension on nullable [String].
extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
