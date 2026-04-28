import 'dart:math';

final _rand = Random.secure();

/// Generates a random RFC 4122 v4 UUID using a cryptographically secure RNG.
String uuidV4() {
  final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10
  String hex(int start, int end) {
    final buf = StringBuffer();
    for (var i = start; i < end; i++) {
      buf.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
