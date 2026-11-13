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

    test('confirm twice does not throw and completes userConfirmed', () async {
      final storage = _Storage()
        ..confirm()
        ..confirm();

      await expectLater(storage.userConfirmed, completes);
    });
  });
}
