import 'package:cmdr/var_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_service_io.dart';

void main() {
  group('VarCache.deallocate', () {
    test('returns true when it removes a var, false when there is none', () {
      final cache = VarCache.preallocate(const [FakeVarKey(1)]);

      expect(cache.deallocate(const FakeVarKey(1)), isTrue);
      expect(cache.contains(const FakeVarKey(1)), isFalse);
      expect(cache.deallocate(const FakeVarKey(1)), isFalse);
    });
  });
}
