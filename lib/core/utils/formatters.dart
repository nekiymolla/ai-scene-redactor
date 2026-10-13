String _two(int v) => v.toString().padLeft(2, '0');

/// `14.10 02:10`
String formatShortDateTime(DateTime t) =>
    '${_two(t.day)}.${_two(t.month)} ${_two(t.hour)}:${_two(t.minute)}';

/// `14.10.2026`
String formatDate(DateTime t) => '${_two(t.day)}.${_two(t.month)}.${t.year}';

/// `0:07`, `1:05`
String formatDuration(Duration d) {
  final totalSeconds = (d.inMilliseconds / 1000).round();
  return '${totalSeconds ~/ 60}:${_two(totalSeconds % 60)}';
}

/// `12,4 МБ`
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} КБ';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} МБ';
}
