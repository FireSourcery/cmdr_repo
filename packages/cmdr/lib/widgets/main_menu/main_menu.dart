import 'dart:ui';
import 'package:flutter/material.dart';

import '../logo.dart';
import 'main_menu_controller.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({required this.background, required this.menuController, this.useIndicator, super.key});
  final ImageProvider<AssetBundleImageKey> background;
  final MainMenuController menuController;
  final bool? useIndicator;

  Widget _navigationRail(BuildContext _, Widget? __) {
    return NavigationRail(
      selectedIndex: menuController.selectedIdByIndex,
      extended: menuController.isExpanded,
      onDestinationSelected: (index) => menuController.selectedIdByIndex = index,
      labelType: NavigationRailLabelType.none,
      useIndicator: useIndicator,
      leading: Column(
        children: [
          MenuLeading(
            collapsedButton: LogoButton.icon(onPressed: menuController.toggleExpanded),
            expandedButton: LogoButton.wide(onPressed: menuController.toggleExpanded),
          ),
          // const Divider(thickness: 0, color: Colors.transparent),
        ],
      ),
      destinations: [
        for (final entry in menuController.menuList)
          NavigationRailDestination(
            padding: const EdgeInsets.symmetric(vertical: 15), // padding matches M2 theme
            icon: Icon(entry.icon),
            label: Text(entry.label, textAlign: TextAlign.center),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuContainer(
      background: background,
      child: ListenableBuilder(listenable: menuController, builder: _navigationRail),
    );
  }
}

class RightMenu extends StatelessWidget {
  const RightMenu({required this.menuController, required this.background, super.key});
  final ImageProvider<AssetBundleImageKey> background;
  final MainMenuController menuController;

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: MainMenu(background: background, menuController: menuController, useIndicator: false));
  }
}

// Filled Scrollable Side Panel
// stretch ScrollView height available
class MenuContainer extends StatelessWidget {
  const MenuContainer({required this.background, this.edgeInsets = const EdgeInsets.symmetric(horizontal: 5), required this.child, super.key});
  final ImageProvider<Object> background;
  final EdgeInsets edgeInsets;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            margin: edgeInsets,
            clipBehavior: Clip.none,
            decoration: BoxDecoration(image: DecorationImage(image: background, fit: BoxFit.fill)),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}

class MenuLeading extends StatelessWidget {
  const MenuLeading({this.collapsedButton, this.expandedButton, this.alignment = AlignmentDirectional.centerStart, this.inset = 10, super.key});
  final Widget? collapsedButton;
  final Widget? expandedButton;
  final AlignmentDirectional alignment;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final animation = NavigationRail.extendedAnimation(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          alignment: alignment,
          clipBehavior: Clip.none,
          child: (animation.value == 0)
              ? collapsedButton
              : Align(
                  alignment: alignment,
                  widthFactor: animation.value,
                  child: Padding(padding: EdgeInsetsDirectional.only(start: lerpDouble(0, inset, animation.value)!), child: expandedButton), // shift towards center
                  // child: Padding(padding: const EdgeInsetsDirectional.only(start: 10), child: expandedButton), // shift towards center
                ),
        );
      },
    );
  }
}
