import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'file_storage_notifier.dart';
import 'file_storage.dart';

class OpenFileButton extends FileLoadButton {
  const OpenFileButton({required super.fileNotifier, super.title = 'Open File', super.iconData = Icons.file_open, super.key});

  @override
  Future<void> beginAsync() async => fileNotifier.openParseWithNotify(fileNotifier.pickFile());
}

class SaveFileButton extends FileLoadButton {
  const SaveFileButton({required super.fileNotifier, super.title = 'Save File', super.iconData = Icons.file_copy, super.key});

  @override
  Future<void> beginAsync() async => fileNotifier.saveBuildWithNotify(fileNotifier.pickSaveFile());
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.fileNotifier, {super.key});
  final FileStorageNotifier fileNotifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FutureBuilder(
        future: fileNotifier.operationCompleted,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return switch (snapshot) {
            AsyncSnapshot(hasError: true) => Text('Error: ${snapshot.error}'), // if user operation throws error
            AsyncSnapshot(connectionState: ConnectionState.done) => Text('Complete: ${fileNotifier.status}'),
            AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.waiting) =>
              ValueListenableBuilder(valueListenable: fileNotifier.statusNotifier, builder: (context, value, child) => Text(value ?? '')),
          };
        },
      ),
    );
  }
}

// async notifier, refresh on show dialog
abstract class FileLoadButton extends StatelessWidget {
  const FileLoadButton({required this.fileNotifier, required this.title, required this.iconData, super.key});
  final FileStorageNotifier fileNotifier;
  final String title; // e.g. open close
  final IconData iconData; // e.g. Icons.file_open

  Future<void> beginAsync(); // load initial async state referenced by dialog

  // Future object reference is set once initially. changes do not update without ChangeNotifier.
  // ConnectionState will not be ConnectionState.none in the case of StatelessWidget
  @override
  Widget build(BuildContext context) {
    Future<String?> showDialogBegin() {
      beginAsync();

      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // insetPadding: EdgeInsets.all(10),
            title: Text(title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // file name
                FutureBuilder(
                  future: fileNotifier.pickedFileName,
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.done) => Text(snapshot.data ?? snapshot.error.toString()),
                      _ => const LinearProgressIndicator(),
                    };
                  },
                ),
                // file loading, then operation status
                _StatusText(fileNotifier),
              ],
            ),
            actions: <Widget>[
              FutureBuilder(
                future: fileNotifier.operationCompleted,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.done) => TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Ok')),
                    _ => const CircularProgressIndicator(),
                  };
                },
              ),
            ],
          );
        },
      );
    }

    return ElevatedButton.icon(
      onPressed: showDialogBegin,
      icon: Icon(iconData),
      label: Text(title),
    );
  }
}

// with nested futures
class FileConfirmationDialogButton extends StatelessWidget {
  const FileConfirmationDialogButton({required this.fileNotifier, required this.title, required this.iconData, required this.onConfirmOperation, super.key});
  final FileStorageNotifier fileNotifier;
  final String title;
  final IconData iconData;
  final AsyncCallback onConfirmOperation;

  void _onConfirm() {
    fileNotifier.confirm();
    fileNotifier.processWithNotify(onConfirmOperation);
  }

  @override
  Widget build(BuildContext context) {
    Future<String?> showDialogBegin() {
      fileNotifier.initUserConfirmation();

      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // insetPadding: EdgeInsets.all(10),
            title: Text(title),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                /// FileName
                Text(fileNotifier.filePath ?? 'No file selected'),
                const Divider(color: Colors.transparent),

                /// Progress Status
                FutureBuilder(
                  future: fileNotifier.userConfirmed,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.waiting) => const Text('Confirm?'),
                      AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder(valueListenable: fileNotifier.progressNotifier, builder: (context, value, child) => LinearProgressIndicator(value: value)),
                            _StatusText(fileNotifier),
                          ],
                        ),
                    };
                  },
                ),
              ],
            ),

            /// Buttons
            actions: <Widget>[
              // cancel button
              FutureBuilder(
                future: fileNotifier.userConfirmed,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Cancel')),
                    AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => const SizedBox.shrink(),
                  };
                },
              ),
              // confirm/ok button
              FutureBuilder(
                future: fileNotifier.userConfirmed,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: _onConfirm, child: const Text('Confirm')),

                    /// after confirmation
                    AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) => FutureBuilder(
                        future: fileNotifier.operationCompleted,
                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                          return switch (snapshot) {
                            AsyncSnapshot(connectionState: ConnectionState.waiting) => const CircularProgressIndicator(),
                            AsyncSnapshot(connectionState: ConnectionState.none || ConnectionState.active || ConnectionState.done) =>
                              TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Ok')),
                          };
                        },
                      ),
                  };
                },
              ),
            ],
          );
        },
      );
    }

    return ElevatedButton.icon(
      onPressed: showDialogBegin,
      icon: Icon(iconData),
      label: Text(title),
    );
  }
}

extension FileStoragePickFile on FileStorage {
  /// File picker using settings
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    allowedExtensions ??= extensions;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      lockParentWindow: true,
      allowMultiple: false,
    );
    return (result != null) ? File(result.files.single.path!) : null;
  }

  Future<File?> pickSaveFile({List<String>? allowedExtensions, String? defaultName}) async {
    allowedExtensions ??= extensions;
    defaultName ??= defaultName;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      String? path = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        lockParentWindow: true,
        dialogTitle: 'Save As:',
        fileName: defaultName,
      );
      return (path != null) ? File(path) : null;
    } else {
      return pickFile();
    }
  }
}

// class FileButtonTheme extends ThemeExtension<FileButtonTheme> {
//   const FileButtonTheme({this.buttonStyle});

//   final ButtonStyle? buttonStyle;

//   final IconData openIcon = Icons.file_open;
//   final IconData saveIcon = Icons.file_copy;
//   final String openTitle = 'Open File';
//   final String saveTitle = 'Save File';

//   Color? get iconColorAsBackgroundColor => buttonStyle?.backgroundColor?.resolve({});

//   @override
//   FileButtonTheme copyWith({
//     ButtonStyle? buttonStyle,
//   }) {
//     return FileButtonTheme(
//       buttonStyle: buttonStyle ?? this.buttonStyle,
//     );
//   }

//   @override
//   ThemeExtension<FileButtonTheme> lerp(covariant ThemeExtension<FileButtonTheme>? other, double t) {
//     throw UnimplementedError();
//   }
// }
