import 'dart:ui';
import 'package:flutter/material.dart';

import '../app_general/logo.dart';
import 'main_menu_controller.dart';

class const MainMenu({required final ImageProvider<AssetBundleImageKey> background, required final MainMenuController menuController, final bool? useIndicator, super.key, final Widget? trailing}) extends StatelessWidget {
  Widget _navigationRail(BuildContext _, Widget? _) {
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
      trailing: trailing,
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

class const RightMenu({required final MainMenuController menuController, required final ImageProvider<AssetBundleImageKey> background, super.key, final Widget? trailing}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MainMenu(background: background, menuController: menuController, useIndicator: false, trailing: trailing),
    );
  }
}

// Filled Scrollable Side Panel
// stretch ScrollView height available
class const MenuContainer({required final ImageProvider<Object> background, final EdgeInsets edgeInsets = const EdgeInsets.symmetric(horizontal: 5), required final Widget child, super.key}) extends StatelessWidget {
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
            decoration: BoxDecoration(
              image: DecorationImage(image: background, fit: BoxFit.fill),
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}

class const MenuLeading({final Widget? collapsedButton, final Widget? expandedButton, final AlignmentDirectional alignment = AlignmentDirectional.centerStart, final double inset = 10, super.key}) extends StatelessWidget {
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
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: lerpDouble(0, inset, animation.value)!),
                    child: expandedButton,
                  ), // shift towards center
                ),
        );
      },
    );
  }
}
