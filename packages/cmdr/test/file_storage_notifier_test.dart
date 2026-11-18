import 'package:cmdr/file_storage/file_storage.dart';
import 'package:cmdr/file_storage/file_storage_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class _Storage() extends FileStorage<String> with FileStorageNotifier<String> {
  this : super(extensions: ['txt'], defaultName: 'report');

  @override
  Codec<String, String> get stringCodec => const _IdentityCodec();

  @override
  String buildContents() => '';

  @override
  Object? parseContents(String contents) => contents;
}

class const _IdentityCodec() extends Codec<String, String> {
  @override
  Converter<String, String> get decoder => const _IdentityConverter();

  @override
  Converter<String, String> get encoder => const _IdentityConverter();
}

class const _IdentityConverter() extends Converter<String, String> {
  @override
  String convert(String input) => input;
}

void main() {
  group('FileStorageNotifier', () {
    test('setting status updates statusNotifier', () {
      final storage = _Storage()..status = 'Saved';

      expect(storage.statusNotifier.value, 'Saved');
      expect(storage.status, 'Saved');
    });

    test('confirm completes userConfirmed, once per initUserConfirmation', () async {
      final storage = _Storage()..confirm();

      await expectLater(storage.userConfirmed, completes);
      expect(storage.confirm, throwsStateError);
    });

    test('processWithNotify passes an error to its caller, and the status keeps the stage', () async {
      final storage = _Storage();

      await expectLater(
        storage.processWithNotify<String>(() async {
          storage.status = 'Erasing...';
          throw Exception('erase failed');
        }),
        throwsException,
      );
      expect(storage.statusNotifier.value, 'Erasing...');
    });

    test('dispose releases its notifiers', () {
      final storage = _Storage()..dispose();

      for (final notifier in [storage.fileNotifier, storage.statusNotifier, storage.progressNotifier]) {
        expect(() => notifier.addListener(() {}), throwsFlutterError);
      }
    });
  });
}
