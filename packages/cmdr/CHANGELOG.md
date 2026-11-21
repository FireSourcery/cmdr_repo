## Unreleased

Breaking:
* `serial_link.dart`, `serial_link_view.dart`, `mot_connection/mot_connection.dart`, `var_notifier/var_notifier.dart`, `time_chart/time_chart.dart`, `var_widgets.dart` and `var_menu.dart` no longer re-export what they import (libserialport, `Link`, `Protocol`, struct_data, the chart and var widget files, the flyweight menu). Import the barrels (`connection.dart`, `mot_connection.dart`, `var_notifier.dart`, `widgets.dart`), or the flyweight files directly.
* `SerialLink.connect()` takes no arguments: set `portConfigName` and `baudRate` first. `baudRate` (an `int`) replaces `portConfig`, which is now built for each session.
* `Link.status` (`ValueListenable<LinkStatus>`) is a new member of `Link`. It publishes the outcome of every `connect` and `disconnect`, a lost link included. `MotConnection.status` is the serial link's, a `ValueListenable` and no longer a `ValueNotifier` it sets.
* `FlyweightMenu` binds its item buttons when it is created. `FlyweightMenuItem` is a data class, not a widget; `FlyweightMenu` holds its `FlyweightMenuSource` and builds its own `MenuItemButton`s. The `FlyweightMenuContext` lookup is gone; the first design is parked, unexported, in `flyweight_menu_v0.dart`.
* `Link.connect` returns `Future<LinkStatus>`. `SerialLink` reaches libserialport only when it opens a port, and frees a closed port one second after closing it: its reader isolate stops only by reading the closed port, within one of its 500 ms waits.
* `DriveShift` renders the gear the device reports: `actual` (a `ValueListenable<Enum?>`) replaces `initialSelect`, and `onSelect` is an `AsyncValueSetter<Enum>`, so a request shows pending until it and `confirmSelected` answer.
* `IOFieldConfig.copyWith(sliderChanged:)` is `valueChanged:`, the field it always set.
* `MenuAnchorOverlay` has no `menuController` parameter: it owns one `MenuController` across rebuilds.
* `PortDetailsView` takes a `PortDetails?` snapshot (`SerialLinkConfigController.portDetails`, taken when the port name changes); no native port is opened in `build`.
* `FileConfirmationDialogButton` is generic and takes `styleId`, `enabled` and `resultContent`.
* `FileStorageNotifier`: `confirm()` completes once (a second call throws), `processWithNotify` returns `Future<R>` and rethrows, and `dispose()` is new.
* `VarStreamController`: `beginPeriodic` and `endPeriodic` are `begin` and `end`. `pause`, `resume` and `isActive` are removed: a paused stream delivered its slice in flight on resume, a view into a reply buffer reused meanwhile. `hold` ends the streams for its action and begins them again if they ran.
* Removed, with no callers: `VarCache.allocateAll`; `ServiceStreamHandler` and its two subclasses; the parameters `updateByData(overwriteUpdateByView:)`, `VarIOField(key:)`, `VarIOField.compact(key:, controller:)`, `IOField(key:)`, `IOFieldMenu.initialValue`, `IOFieldWithSlider.of(key:)`, `IOFieldConfig.copyWith(useSliderBorder:)`, `StringFormField.isReadOnly`, `Grid3.isHalfLeading`, `DriveShift.size` and `ChartController.loadWithMeta`.

Changed:
* An idle `pollFlex` or `push` loop yields after each idle wait, so `VarStreamController.end` cancels it there. A write that must go out while the streams are ended is a direct `VarCacheController.write` or `writeAll`.
* `Protocol` disconnects its link when a read or write fails or the link's stream ends, and `Link.status` reports it.
* Dialogs take a `styleId` (`DialogButtonStyle`). `DialogButtonStyle.warning` shows the warning icon and the warning Confirm style.
* `copyWith` carries every field. `IOFieldConfig.copyWith` gains `valueNumLimits`. `VarIOFieldConfig.copyWith` forwards all of its fields into an `IOFieldConfig`, whose value getter and setter stay bound to the var.
* A polling var is polled only while it is observed (`VarNotifier.isObserved`: something listens to it) or while a `VarPollingScope` holds it. A scope skips write-only vars.
* `VarStreamController` restarts its poll and push streams independently after an error, after a backoff of 50 ms doubling to 1.6 s. A slice or `end` resets the backoff, and `begin(onError:)` gets the first error of each run of errors. A backoff timer still pending at `end` is left to expire harmlessly: it cannot resubscribe.
* `VarNotifier.applyWriteResponse(sent, status)`: an accepted write commits the sent value unless the view changed since; a rejected write reverts the view to the device value. One notification either way.
* `updateByData` does not notify when the device value is unchanged, and setting an unchanged `statusCode` does not notify.
* Mot wire format: the `MemReadRequest` payload is 8 bytes (was 12), as the firmware reads it; `MotPacketControlId.MOT_PACKET_SYNC_RESV` is retired (commented out) to match the firmware's control-frame ids.

Added:
* `MainMenu`, `MenuContainer` and `BottomSheetButton` take a `backdrop` widget; the background image is now optional. The menu paints it behind its content; the button bar paints it over its surface and border and under its button, taps passing through. The app draws its animated borders there.

Fixed:
* `VarStreamController.end` clears its subscriptions before awaiting their cancels, so a `begin` in that wait (a fast reconnect) starts new streams instead of leaving the app connected with none.
* `DriveShift` clears its pending state when `onSelect` throws; the error still propagates.
* `ChartData.fromMap` takes the time series from the column named `time`, not from the first column.
* `IOFieldText` clears its parse error when its `listenable` changes, so a reused field shows the new var's value.
* `VarCache.deallocate` returns false when nothing was removed.
* `IOFieldMenu` keeps its key on the menu, not on its reader, and shows its tip once.
* `DialogAnchor` follows a replaced `eventNotifier`.

Dependencies:
* `flutter_libserialport` moved into this package: it builds and deploys the C library `libserialport` loads. `quiver` and `flutter_form_builder` removed.
* Lints: `flutter_lints`, then the shared rules of the repository root.

## 0.0.1

* Initial version.
