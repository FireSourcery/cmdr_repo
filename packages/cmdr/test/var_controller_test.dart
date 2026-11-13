import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_service_io.dart';

void main() {
  const keys = [FakeVarKey(1), FakeVarKey(2), FakeVarKey(3)];
  const device = {1: 10, 2: 20, 3: 30};
  const edit = -1;

  late FakeServiceIO service;
  late VarCacheController controller;

  Iterable<VarNotifier> varsOf(Iterable<VarKey> keys) => controller.cache.varsOf(keys);

  setUp(() {
    service = FakeServiceIO({...device}, batchSize: 2);
    controller = VarCacheController(cache: VarCache.preallocate(keys), protocolService: service);
    for (final v in controller.cache.varEntries) {
      v.updateByView(edit);
    }
  });

  tearDown(() => controller.dispose());

  group('VarCacheController.readOverwrite', () {
    test('a slice with no response returns the failure, and the edits on every var survive', () async {
      service.getReplies.addAll([service.readDevice, (_) => null]);

      expect(await controller.readOverwrite(), isNull);
      expect(varsOf(keys).map((v) => (v.hasPendingChanges, v.value)), everyElement((true, edit)));
    });

    test('on success the edits on keys are discarded for the device values, and the edits on other vars survive', () async {
      expect((await controller.readOverwrite(keys.take(2)))?.isSuccess, isTrue);
      expect(varsOf(keys.take(2)).map((v) => (v.hasPendingChanges, v.value)), [(false, 10), (false, 20)]);
      expect(varsOf(keys.skip(2)).map((v) => (v.hasPendingChanges, v.value)), [(true, edit)]);
    });

    test('with no keys every edit is discarded for the device values', () async {
      expect((await controller.readOverwrite())?.isSuccess, isTrue);
      expect(varsOf(keys).map((v) => (v.hasPendingChanges, v.value)), [(false, 10), (false, 20), (false, 30)]);
    });
  });

  group('write responses reconcile the view by status', () {
    const rejected = 2;

    (bool, Object?, int) viewOf(VarNotifier v) => (v.hasPendingChanges, v.value, v.statusCode);

    setUp(() => controller.readAll());

    test('writeUpdated reverts a rejected var to the device value, commits the accepted vars, and reports the error', () async {
      final notifications = <int>[];
      controller.cache[keys[1]]!.addListener(() => notifications.add(1));
      service.setReplies.add((pairs) => [...service.writeDevice(pairs.take(1)), rejected]);

      expect((await controller.writeUpdated())?.code, rejected);
      expect(varsOf(keys).map(viewOf), [(false, edit, 0), (false, 20, rejected), (false, edit, 0)]);
      expect(notifications, hasLength(1));
    });

    test('writeUpdated finishes every slice after one with no response, and reports the failure', () async {
      service.setReplies.add((_) => null);

      expect(await controller.writeUpdated(), isNull);
      expect(varsOf(keys).map(viewOf), [(true, edit, 0), (true, edit, 0), (false, edit, 0)]);
    });

    test('write commits an accepted value', () async {
      expect((await controller.write(keys.first))?.isSuccess, isTrue);
      expect(viewOf(controller.cache[keys.first]!), (false, edit, 0));
      expect(service.device[1], edit);
    });

    test('send reverts a rejected value to the device value', () async {
      service.setReplies.add((_) => [rejected]);

      expect((await controller.single(controller.cache[keys.first]!).send(5))?.code, rejected);
      expect(viewOf(controller.cache[keys.first]!), (false, 10, rejected));
    });

    test('write on an uncached key returns null and sends nothing', () async {
      expect(await controller.write(const FakeVarKey(4)), isNull);
      expect(service.device, device);
    });
  });
}
