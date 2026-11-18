import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_service_io.dart';

/// [VarStreamController] over a [FakeServiceIO], in the fake time of [testWidgets]: `tester.pump(d)` runs the streams for `d`.
void main() {
  const scoped = FakeVarKey(1);
  const writeOnly = FakeVarKey(2, access: VarReadWriteAccess.writeOnly);
  const polling = FakeVarKey(3, isPolling: true);
  const device = {1: 10, 2: 20, 3: 30};
  const delay = VarStreamController.restartDelay;
  const tick = Duration(milliseconds: 1);
  const round = Duration(milliseconds: 60); // past the 50 ms idle wait of a stream with no keys

  late FakeServiceIO service;
  late VarStreamController controller;
  late List<Object> errors;
  late int failures;

  int? valueOf(VarKey key) => controller.cache[key]?.value as int?;
  Iterable<int>? fail(Iterable<Object> _) => throw StateError('link fault ${++failures}');

  setUp(() {
    service = FakeServiceIO({...device});
    controller = VarStreamController(cache: VarCache.preallocate(const [scoped, writeOnly, polling]), protocolService: service);
    errors = [];
    failures = 0;
  });

  tearDown(() => controller.dispose());

  // runs fake time past the longest backoff, so no timer outlives the test
  Future<void> end(WidgetTester tester) async {
    controller.endPeriodic();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.isStopped, isTrue);
  }

  group('VarStreamController.endPeriodic', () {
    testWidgets('completes while nothing is polled, and a beginPeriodic after it starts a fresh stream', (tester) async {
      controller.beginPeriodic();
      await tester.pump(round);
      final idle = controller.pollSubscription;
      var ended = false;
      controller.endPeriodic().whenComplete(() => ended = true);
      await tester.pump(round);
      expect((ended, controller.isStopped), (true, true));

      controller.createScope(const [scoped]);
      controller.beginPeriodic();
      await tester.pump(round);
      expect(controller.pollSubscription, isNot(same(idle)));
      expect(valueOf(scoped), 10);
      await end(tester);
    });

    testWidgets('a beginPeriodic while its cancels are still pending starts a run that stays, as a fast reconnect does', (tester) async {
      controller.beginPeriodic();
      await tester.pump(round);
      controller.endPeriodic(); // the idle loops cancel at their next yield, after the 50 ms wait
      controller.createScope(const [scoped]);
      controller.beginPeriodic();
      await tester.pump(round * 2);

      expect(controller.isStopped, isFalse);
      expect(valueOf(scoped), 10);
      await end(tester);
    });
  });

  group('the restart policy', () {
    testWidgets('a failed poll restarts after restartDelay, doubling with each error in a row, and reports only the first', (tester) async {
      service.getReplies.addAll([fail, fail, fail, fail]);
      controller.createScope(const [scoped]);
      controller.beginPeriodic(onError: errors.add);
      await tester.pump();
      expect(failures, 1);

      for (final (wait, attempt) in [(delay, 2), (delay * 2, 3), (delay * 4, 4)]) {
        await tester.pump(wait - tick);
        expect(failures, attempt - 1);
        await tester.pump(tick);
        expect(failures, attempt);
      }
      await tester.pump(delay * 8);
      expect((valueOf(scoped), errors.length), (10, 1));
      expect(errors.single, isA<StateError>().having((e) => e.message, 'message', 'link fault 1'));
      await end(tester);
    });

    testWidgets('a slice ends the burst: the next error is reported, and its restart waits restartDelay again', (tester) async {
      service.getReplies.addAll([fail, fail]);
      controller.createScope(const [scoped]);
      controller.beginPeriodic(onError: errors.add);
      await tester.pump(delay * 4);
      expect((failures, valueOf(scoped), errors.length), (2, 10, 1));

      service.getReplies.add(fail);
      service.device[1] = 11;
      await tester.pump(tick);
      expect((failures, errors.length), (3, 2));
      await tester.pump(delay);
      expect(valueOf(scoped), 11);
      await end(tester);
    });

    testWidgets('a failed push restarts after restartDelay, and the write lands', (tester) async {
      service.setReplies.add(fail);
      controller.cache[scoped]!.updateByView(5);
      controller.beginPeriodic(onError: errors.add);
      await tester.pump();
      expect((failures, errors.length), (1, 1));

      await tester.pump(delay - tick);
      expect(service.device[1], 10);
      await tester.pump(tick);
      expect(service.device[1], 5);
      await end(tester);
    });

    testWidgets('the poll stream restarts on its own subscription, whatever the push stream holds', (tester) async {
      service.getReplies.add(fail);
      controller.createScope(const [scoped]);
      controller.beginPeriodic(onError: errors.add);
      controller.pushSubscription?.cancel();
      controller.pushSubscription = null;
      await tester.pump(delay);
      expect((failures, valueOf(scoped)), (1, 10));
      await end(tester);
    });
  });

  // a cancel during a backoff completes in a root zone microtask, which the fake time of testWidgets does not run
  group('in real time, ending during a backoff', () {
    test('endPeriodic completes and cancels the restart', () async {
      service.getReplies.add(fail);
      controller.createScope(const [scoped]);
      controller.beginPeriodic(onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      expect(failures, 1);

      await controller.endPeriodic();
      await Future<void>.delayed(delay * 2);
      expect((controller.isStopped, failures, valueOf(scoped)), (true, 1, 0));
    });

    test('a beginPeriodic after it reports its first error', () async {
      service.getReplies.addAll([fail, fail]);
      controller.createScope(const [scoped]);
      controller.beginPeriodic(onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      await controller.endPeriodic();

      controller.beginPeriodic(onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      expect((failures, errors.length), (2, 2));
      await controller.endPeriodic();
    });
  });

  group('poll selection', () {
    testWidgets('a polling var is polled while it is observed', (tester) async {
      void listener() {}
      final notifier = controller.cache[polling]!;
      controller.beginPeriodic();
      await tester.pump(round);
      expect(valueOf(polling), 0);

      notifier.addListener(listener);
      await tester.pump(round);
      expect(valueOf(polling), 30);

      notifier.removeListener(listener);
      service.device[3] = 31;
      await tester.pump(round);
      expect(valueOf(polling), 30);
      await end(tester);
    });

    testWidgets('a scope polls its readable keys, from createScope and from update', (tester) async {
      final scope = controller.createScope(const [scoped, writeOnly]);
      controller.beginPeriodic();
      await tester.pump(round);
      expect([valueOf(scoped), valueOf(writeOnly)], [10, 0]);

      service.device.addAll({1: 11, 2: 21});
      scope.update(const [writeOnly]);
      await tester.pump(round);
      expect([valueOf(scoped), valueOf(writeOnly)], [10, 0]);

      scope.update(const [scoped, writeOnly]);
      await tester.pump(round);
      expect([valueOf(scoped), valueOf(writeOnly)], [11, 0]);
      await end(tester);
    });
  });
}
