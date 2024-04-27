import 'package:flutter/material.dart';

/// Screen Layouts

class ExpandedColumnExpanded extends StatelessWidget {
  const ExpandedColumnExpanded(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [for (final child in children) Expanded(child: child)]));
}

class ExpandedRowExpanded extends StatelessWidget {
  const ExpandedRowExpanded(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Expanded(child: Row(children: [for (final child in children) Expanded(child: child)]));
}

class FlexExpanded extends StatelessWidget {
  const FlexExpanded(this.direction, this.children, {super.key});
  final Axis direction;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Flex(direction: direction, children: [for (final child in children) Expanded(child: child)]);
}

class ExpandedFlexExpanded extends StatelessWidget {
  const ExpandedFlexExpanded(this.direction, this.children, {/* flexfactor */ super.key});
  final Axis direction;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Expanded(child: Flex(direction: direction, children: [for (final child in children) Expanded(child: child)]));
}

class Grid4 extends StatelessWidget {
  const Grid4(this.upperLeft, this.upperRight, this.lowerLeft, this.lowerRight, {super.key});
  Grid4.list(List<Widget> children, {Key? key}) : this(children[0], children[1], children[2], children[3], key: key);

  final Widget upperLeft;
  final Widget upperRight;
  final Widget lowerLeft;
  final Widget lowerRight;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ExpandedRowExpanded([upperLeft, upperRight]),
      ExpandedRowExpanded([lowerLeft, lowerRight])
    ]);
    // return Flex(children: [
    //   ExpandedFlexExpanded([upperLeft, upperRight]),
    //   ExpandedFlexExpanded([lowerLeft, lowerRight])
    // ]);
  }
}

class Grid3 extends StatelessWidget {
  const Grid3(this.half, this.quarter1, this.quarter2, {this.direction = Axis.horizontal, this.isHalfLeading = true, super.key});
  final Widget half;
  final Widget quarter1;
  final Widget quarter2;
  final Axis direction;
  final bool isHalfLeading;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      // todo select if half is first top/left
      children: [
        ExpandedFlexExpanded(flipAxis(direction), [half]),
        ExpandedFlexExpanded(flipAxis(direction), [quarter1, quarter2])
      ],
    );
  }
}

class Grid2 extends StatelessWidget {
  const Grid2(this.half1, this.half2, {this.direction = Axis.horizontal, super.key});
  final Axis direction;
  final Widget half1;
  final Widget half2;

  @override
  Widget build(BuildContext context) => FlexExpanded(direction, [half1, half2]);
}

class ExpandedCard extends StatelessWidget {
  const ExpandedCard(this.child, {super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: child))));
}

class Grid6 extends StatelessWidget {
  const Grid6({
    required this.leftPanel,
    required this.rightPanel,
    required this.bottomLeftLeft,
    required this.bottomLeftCenter,
    required this.bottomRightCenter,
    required this.bottomRightRight,
    super.key,
  });
  final Widget leftPanel;
  final Widget rightPanel;
  final Widget bottomLeftLeft;
  final Widget bottomLeftCenter;
  final Widget bottomRightCenter;
  final Widget bottomRightRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 5, child: Row(children: [ExpandedCard(leftPanel), ExpandedCard(rightPanel)])),
        Expanded(flex: 3, child: Row(children: [ExpandedCard(bottomLeftLeft), ExpandedCard(bottomLeftCenter), ExpandedCard(bottomRightCenter), ExpandedCard(bottomRightRight)])),
      ],
    );
  }
}

// class CardListTileText extends StatelessWidget {
//   const CardListTileText(this.subtitle, this.title, {super.key});
//   final String? subtitle; // or caption
//   final String? title; // value
//   @override
//   Widget build(BuildContext context) => Card(child: ListTile(title: Text(title ?? ''), subtitle: Text(subtitle ?? '')));
// }
