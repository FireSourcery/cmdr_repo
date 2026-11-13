import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class const _Key(@override final int value) with VarKey<int> {
  @override
  TypeKey<int> get viewType => const TypeKey<int>();
  @override
  BinaryCodec<int> buildViewer() => throw UnimplementedError();
  @override
  String stringify<V1>(V1 value) => '$value';
  @override
  VarStatus varStatusOf(int code) => VarStatus.defaultOf(code);
  @override
  bool get isPolling => false;
  @override
  bool get isPushing => false;
  @override
  VarReadWriteAccess get access => VarReadWriteAccess.readWrite;
  @override
  List<VarKey>? get dependents => null;
  @override
  String get label => 'key$value';
  @override
  String? get suffix => null;
  @override
  String? get tip => null;
}

void main() {
  group('VarKey ==', () {
    test('keys with the same value are equal and hash alike', () {
      expect(const _Key(3), const _Key(3));
      expect(const _Key(3).hashCode, const _Key(3).hashCode);
    });

    test('keys with different values are not equal', () {
      expect(const _Key(3) == const _Key(4), isFalse);
    });

    test('a non-VarKey operand is not equal and does not throw', () {
      expect((const _Key(3) as Object) == 'x', isFalse);
    });
  });
}
