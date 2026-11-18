import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_service_io.dart';

void main() {
  const key = FakeVarKey(1);

  late FakeServiceIO service;
  late VarCacheController controller;
  late VarNotifier notifier;
  late int notifications;

  setUp(() {
    notifications = 0;
    service = FakeServiceIO({1: 10});
    controller = VarCacheController(cache: VarCache.preallocate(const [key]), protocolService: service);
    notifier = controller.cache[key]!..addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('a read of the held value does not notify, a changed value notifies once', () async {
    await controller.readAll();
    await controller.readAll();
    expect((notifier.value, notifications), (10, 1));

    service.device[1] = 11;
    await controller.readAll();
    expect((notifier.value, notifications), (11, 2));
  });

  test('an equal status does not notify, a changed one notifies once', () {
    notifier.statusCode = 0;
    expect(notifications, 0);

    notifier.statusCode = 2;
    notifier.statusCode = 2;
    expect((notifier.statusCode, notifications), (2, 1));
  });

  test('isObserved reflects listeners', () {
    void listener() {}
    final other = const FakeVarKey(2).create();
    addTearDown(other.dispose);

    expect((notifier.isObserved, other.isObserved), (true, false));
    other.addListener(listener);
    expect(other.isObserved, isTrue);
    other.removeListener(listener);
    expect(other.isObserved, isFalse);
  });
}
