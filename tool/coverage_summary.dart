// Prints a coverage summary from coverage/lcov.info.
// Run after `flutter test --coverage`:
//   dart run tool/coverage_summary.dart
import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info not found. Run: flutter test --coverage');
    exit(1);
  }

  final found = <String, int>{};
  final hit = <String, int>{};
  String? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll('\\', '/');
    } else if (line.startsWith('LF:') && current != null) {
      found[current] = int.parse(line.substring(3));
    } else if (line.startsWith('LH:') && current != null) {
      hit[current] = int.parse(line.substring(3));
    }
  }

  var totalFound = 0;
  var totalHit = 0;
  stdout.writeln('File'.padRight(48) + 'Lines'.padLeft(10) + 'Covered'.padLeft(10));
  final files = found.keys.toList()..sort();
  for (final f in files) {
    final lf = found[f]!;
    final lh = hit[f] ?? 0;
    totalFound += lf;
    totalHit += lh;
    final pct = lf == 0 ? 100.0 : lh * 100 / lf;
    stdout.writeln(f.padRight(48) + '$lh/$lf'.padLeft(10) + '${pct.toStringAsFixed(1)}%'.padLeft(10));
  }
  final total = totalFound == 0 ? 0.0 : totalHit * 100 / totalFound;
  stdout.writeln('-' * 68);
  stdout.writeln('TOTAL'.padRight(48) + '$totalHit/$totalFound'.padLeft(10) + '${total.toStringAsFixed(1)}%'.padLeft(10));
}
