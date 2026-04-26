import 'dart:math';

class CorrelationId {
  CorrelationId._();

  static final Random _random = Random.secure();

  static String create({String prefix = 'txn'}) {
    final milliseconds = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return '$prefix-$milliseconds-$randomPart';
  }
}
