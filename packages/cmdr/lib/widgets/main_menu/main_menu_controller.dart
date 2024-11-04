import '../../settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

class LinkedMenuController {
  LinkedMenuController(List<MenuEntry> menuListMain, List<MenuEntry> menuListAux)
      : mainMenu = MainMenuController(menuListMain, createNavigatorKey: true),
        auxMenu = MainMenuController(menuListAux, createNavigatorKey: false);

  final MainMenuController mainMenu;
  final MainMenuController auxMenu;

  set auxMenuList(List<MenuEntry>? menuList) => auxMenu.menuList = menuList;

  Enum get mainSelectedId => mainMenu.selectedId;
  Enum get auxSelectedId => auxMenu.selectedId;

  void toggleDouble() {
    mainMenu.toggleExpanded();
    auxMenu.isExpanded = mainMenu.isExpanded;
  }
}

/// is expanded and selecct are on the same notifier
class MainMenuController with ChangeNotifier {
  MainMenuController(this.initialMenuList, {GlobalKey<NavigatorState>? navigatorKey, bool createNavigatorKey = false})
      : assert(!(navigatorKey != null && createNavigatorKey == true)),
        navigatorKey = createNavigatorKey ? GlobalKey() : navigatorKey;

  final List<MenuEntry> initialMenuList;
  final GlobalKey<NavigatorState>? navigatorKey;

  late List<MenuEntry> _menuList = initialMenuList;
  List<MenuEntry> get menuList => _menuList;
  set menuList(List<MenuEntry>? value) {
    _menuList = value ?? initialMenuList;
    _selectedId = menuList.first.id;
    notifyListeners();
  }

  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;
  set isExpanded(bool value) {
    _isExpanded = value;
    notifyListeners();
  }

  void toggleExpanded() => isExpanded = !isExpanded;

  late Enum _selectedId = menuList.first.id;
  Enum get selectedId => _selectedId;
  set selectedId(Enum value) {
    _selectedId = value;
    navigatorKey?.currentState!.restorablePushReplacementNamed(selectedRoute);
    notifyListeners();
  }

  // int indexOf(Enum id) => id.index;
  int indexOf(Enum id) => menuList.indexWhere((menuEntry) => (menuEntry.id == id)); // if menu list order different from Enum
  Enum idOf(int index) => menuList[index].id;

  int get selectedIdByIndex => indexOf(selectedId);
  set selectedIdByIndex(int value) => selectedId = idOf(value);

  String get selectedRoute => menuList[indexOf(selectedId)].route ?? '';
  String get selectedLabel => menuList[indexOf(selectedId)].label;
}

class MenuEntry {
  const MenuEntry({required this.id, this.label = '', this.icon, this.route, this.widget});
  final Enum id; // menu in order of index
  final String label;
  final IconData? icon;
  final String? route;
  final Widget? widget;
}

abstract mixin class MenuEntryId implements MenuEntry, Enum {
  Enum get id => this;
  String get label => name.pascalCase;
  IconData? get icon;
  String? get route;
  Widget? get widget;
}
