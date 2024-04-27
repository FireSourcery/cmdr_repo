import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_notifier.dart';
import 'file_storage.dart';

// async notifier, refresh on show dialogue
abstract class FileLoadButton extends StatelessWidget {
  const FileLoadButton({required this.fileNotifier, required this.title, required this.iconData, super.key});
  final FileNotifier fileNotifier;
  final String title; // e.g. open close
  final IconData iconData; // e.g. Icons.file_open

  // final Widget dialogContent;

  Future<void> beginAsync(); // beginAsync set up show dialog. file operation maps to the same completer

  // change of Future object reference do not update without change notifier.
  // ConnectionState will not be ConnectionState.none
  @override
  Widget build(BuildContext context) {
    Future<String?> showDialogStatus() {
      beginAsync(); // setup completes async before show

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
                  builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.done, :final data) => Text(data ?? 'No file selected'),
                      _ => const LinearProgressIndicator(),
                    };
                  },
                ),
                // file loading, then operation status
                FutureBuilder(
                  future: fileNotifier.operationCompleted,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(hasError: true) => Text('Error: ${snapshot.error}'), // snapshot.error is e from tryProcess
                      // AsyncSnapshot(connectionState: ConnectionState.done) => Text('Complete: ${fileNotifier.status}'),
                      AsyncSnapshot(connectionState: ConnectionState.done) =>
                        ValueListenableBuilder(valueListenable: fileNotifier.statusNotifier, builder: (context, value, child) => Text(value ?? '')),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ],
            ),
            actions: <Widget>[
              FutureBuilder(
                future: fileNotifier.operationCompleted,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(hasError: true) ||
                    AsyncSnapshot(connectionState: ConnectionState.done) =>
                      TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Ok')),
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
      onPressed: showDialogStatus,
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

  @override
  Widget build(BuildContext context) {
    Future<String?> showDialogStatus() {
      fileNotifier.initConfirmationState();

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
                //  FileName
                FutureBuilder(
                  future: fileNotifier.pickCompleted,
                  builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.done) => Text(fileNotifier.filePath.toString()),
                      _ => const Text('No file selected'),
                    };
                  },
                ),
                const Divider(color: Colors.transparent),
                //  Progress Status
                FutureBuilder(
                  future: fileNotifier.userConfirmed,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                    return switch (snapshot) {
                      AsyncSnapshot(connectionState: ConnectionState.waiting) => const Text('Confirm?'),
                      _ => Column(
                          children: [
                            ValueListenableBuilder(valueListenable: fileNotifier.progressNotifier, builder: (context, value, child) => LinearProgressIndicator(value: value)),
                            ValueListenableBuilder(valueListenable: fileNotifier.statusNotifier, builder: (context, value, child) => Text(value ?? '')),
                            FutureBuilder(
                              future: fileNotifier.operationCompleted,
                              builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
                                return switch (snapshot) {
                                  AsyncSnapshot(hasError: true) => Text('Error: ${snapshot.error}'),
                                  AsyncSnapshot(connectionState: ConnectionState.done) => Text('Complete: ${fileNotifier.status}'),
                                  _ => const SizedBox.shrink(),
                                };
                              },
                            ),
                          ],
                        ),
                    };
                  },
                ),
              ],
            ),
            actions: <Widget>[
              FutureBuilder(
                future: fileNotifier.userConfirmed,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Cancel')),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
              FutureBuilder(
                future: fileNotifier.userConfirmed,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  return switch (snapshot) {
                    AsyncSnapshot(connectionState: ConnectionState.waiting) => TextButton(
                        onPressed: () {
                          fileNotifier.confirm();
                          fileNotifier.tryProcess(onConfirmOperation);
                        },
                        child: const Text('Confirm'),
                      ),
                    _ => FutureBuilder(
                        future: fileNotifier.operationCompleted,
                        builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
                          return switch (snapshot) {
                            AsyncSnapshot(connectionState: ConnectionState.waiting) => const CircularProgressIndicator(),
                            _ => TextButton(onPressed: () => Navigator.of(context).pop(fileNotifier.status), child: const Text('Ok')),
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
      onPressed: showDialogStatus,
      icon: Icon(iconData),
      label: Text(title),
    );
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
