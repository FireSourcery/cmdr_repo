import 'package:flutter/material.dart';

// class MainMenu extends StatelessWidget {
//   const MainMenu({super.key});
//   final ImageProvider<AssetBundleImageKey> background = const AssetImage('$imageAssetLocation/left_bg.png');

// // DoubleMenuController mainMenuController;

//   Widget _navigationRail(BuildContext _, Widget? __) {
//     return NavigationRail(
//       selectedIndex: mainMenuController.mainMenu.selectedIdByIndex,
//       extended: mainMenuController.mainMenu.isExpanded,
//       onDestinationSelected: (index) => mainMenuController.mainMenu.selectedIdByIndex = index,
//       labelType: NavigationRailLabelType.none,
//       useIndicator: true,
//       leading: NavLeading(
//         collapsedButton: LogoButton.icon(onPressed: mainMenuController.toggleDouble),
//         expandedButton: LogoButton.wide(onPressed: mainMenuController.toggleDouble),
//       ),
//       destinations: [
//         for (final entry in mainMenuController.mainMenu.menuList)
//           NavigationRailDestination(
//             padding: const EdgeInsets.symmetric(vertical: 15), // padding matches M2 theme
//             icon: Icon(entry.icon),
//             label: Text(entry.label, textAlign: TextAlign.center),
//           ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inner = ListenableBuilder(listenable: mainMenuController.mainMenu, builder: _navigationRail);
//     return SidePanel(background: background, child: inner);
//   }
// }

// //replace with sidehseet
// class RightMenu extends StatelessWidget {
//   const RightMenu({super.key});
//   final ImageProvider<Object> background = const AssetImage('$imageAssetLocation/right_bg.png');

//   Widget _navigationRail(BuildContext context, Widget? __) {
//     final nav = NavigationRail(
//       selectedIndex: mainMenuController.auxMenu.selectedIdByIndex,
//       extended: mainMenuController.auxMenu.isExpanded,
//       onDestinationSelected: (index) => mainMenuController.auxMenu.selectedIdByIndex = index,
//       labelType: NavigationRailLabelType.none,
//       leading: Column(
//         children: [
//           NavLeading(
//             collapsedButton: LogoButton.icon(onPressed: mainMenuController.auxMenu.toggleExpanded),
//             expandedButton: LogoButton.wide(onPressed: mainMenuController.auxMenu.toggleExpanded),
//           ),
//           const Divider(thickness: 0, color: Colors.transparent)
//         ],
//       ),
//       useIndicator: false,
//       // indicatorColor: Colors.transparent,
//       // indicatorShape: CircleBorder(),
//       selectedLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
//       unselectedLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
//       destinations: [
//         for (final entry in mainMenuController.auxMenu.menuList) // padding matches non material 3 theme
//           NavigationRailDestination(
//             padding: const EdgeInsets.symmetric(vertical: 2),
//             icon: (entry.widget != null) ? const Icon(null) : Icon(entry.icon),
//             label: (entry.widget != null) ? _MenuWidgetWrap(child: entry.widget!) : Text(entry.label),
//           ),
//       ],
//     );

//     final theme = Theme.of(context).copyWith(
//       // highlightColor: Colors.transparent,
//       // hoverColor: Colors.transparent,
//       // indicatorColor: Colors.transparent,
//       // splashFactory: NoSplash.splashFactory,
//       // splashColor: Colors.transparent,
//       // focusColor: Colors.transparent,
//       // navigationRailTheme: Theme.of(context).navigationRailTheme.copyWith(
//       //       selectedLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
//       //       unselectedLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
//       //     ),
//       useMaterial3: false,
//     );

//     // return Directionality(textDirection: TextDirection.rtl, child: nav);
//     return Theme(data: theme, child: Directionality(textDirection: TextDirection.rtl, child: nav));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inner = ListenableBuilder(listenable: mainMenuController.auxMenu, builder: _navigationRail);
//     return SidePanel(background: background, child: inner);
//   }
// }

// nav menu frame constraints

//stretch scrollview height available
class SidePanel extends StatelessWidget {
  const SidePanel({required this.background, this.edgeInsets = const EdgeInsets.symmetric(horizontal: 5), required this.child, super.key});
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

class NavLeading extends StatelessWidget {
  const NavLeading({this.collapsedButton, this.expandedButton, this.alignment = AlignmentDirectional.centerStart, super.key});
  final Widget? collapsedButton;
  final Widget? expandedButton;
  final AlignmentDirectional alignment;

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
                  // child: Padding(padding: EdgeInsetsDirectional.only(start: lerpDouble(0, 10, animation.value)!), child: expandedButton), // shift towards center
                  child: Padding(padding: const EdgeInsetsDirectional.only(start: 10), child: expandedButton), // shift towards center
                ),
        );
      },
    );
  }
}
