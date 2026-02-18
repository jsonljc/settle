// Shared helpers for share-sheet text: clean line breaks, no markdown, no emojis.
// Output format: "[Card title]\n[Card body]\n\n— Settle"

/// Strips markdown, emojis, and normalizes whitespace for plain-text share.
String stripForShare(String text) {
  if (text.isEmpty) return text;
  String s = text.trim();
  // Remove markdown: **bold**, *italic*, __underline__, # heading, [label](url)
  s = s.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
  s = s.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
  s = s.replaceAll(RegExp(r'__(.+?)__'), r'$1');
  s = s.replaceAll(RegExp(r'_(.+?)_'), r'$1');
  s = s.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
  s = s.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
  s = s.replaceAllMapped(
      RegExp(r'`[^`]+`'), (Match m) => m.group(0)!.replaceAll('`', ''));
  // Remove emoji (common ranges)
  s = s.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '');
  s = s.replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '');
  s = s.replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '');
  s = s.replaceAll(RegExp(r'[\u{FE00}-\u{FE0F}]', unicode: true), '');
  s = s.replaceAll(RegExp(r'\u200D'), '');
  // Normalize whitespace: collapse multiple spaces/newlines to single, trim lines
  s = s.split('\n').map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' ')).join('\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

/// Builds share text for a card: "[Card title]\n[Card body]\n\n— Settle".
/// Cleans title and body (no markdown, emojis, extra whitespace).
String buildCardShareText(String title, String body) {
  final t = stripForShare(title);
  final b = stripForShare(body);
  if (b.isEmpty) return '$t\n\n— Settle';
  return '$t\n$b\n\n— Settle';
}
