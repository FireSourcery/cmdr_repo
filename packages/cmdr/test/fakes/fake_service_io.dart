import 'dart:collection';

import 'package:cmdr/var_notifier.dart';

/// One scripted batch reply: the values or per-var statuses, `null` for no response, or a throw.
typedef FakeReply<T> = Iterable<int>? Function(Iterable<T> request);

/// A [ServiceIO] over a [device] map. Each batch call, single calls included, takes the next scripted reply;
/// with none queued it answers from [device].
class FakeServiceIO(final Map<int, int> device, {final int? batchSize}) with ServiceIO<int, int, int> {
  final Queue<FakeReply<int>> getReplies = Queue();
  final Queue<FakeReply<(int, int)>> setReplies = Queue();

  List<int> readDevice(Iterable<int> keys) => [for (final key in keys) device[key] ?? 0];

  List<int> writeDevice(Iterable<(int, int)> pairs) {
    device.addAll({for (final (key, value) in pairs) key: value});
    return List.filled(pairs.length, 0);
  }

  @override
  bool get isConnected => true;

  @override
  int? get maxGetBatchSize => batchSize;
  @override
  int? get maxSetBatchSize => batchSize;

  @override
  Iterable<int>? getBatch(Iterable<int> keys) => (getReplies.isEmpty ? readDevice : getReplies.removeFirst())(keys);
  @override
  Iterable<int>? setBatch(Iterable<(int, int)> pairs) => (setReplies.isEmpty ? writeDevice : setReplies.removeFirst())(pairs);

  @override
  int? get(int key) => getBatch([key])?.single;
  @override
  int? set(int key, int value) => setBatch([(key, value)])?.single;
}

/// A readable and writable `int` [VarKey] whose data is its view.
class const FakeVarKey(@override final int value) with VarKey<int> {
  @override
  TypeKey<int> get viewType => const TypeKey<int>();
  @override
  BinaryCodec<int> buildViewer() => BinaryCodec.identity;
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
