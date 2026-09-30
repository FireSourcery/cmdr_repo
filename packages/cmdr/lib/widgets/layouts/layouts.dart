import 'package:flutter/material.dart';

/// Screen Layouts

class const ExpandedColumnExpanded(final List<Widget> children, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [for (final child in children) Expanded(child: child)]),
  );
}

class const ExpandedRowExpanded(final List<Widget> children, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(children: [for (final child in children) Expanded(child: child)]),
  );
}

class const FlexExpanded(final Axis direction, final List<Widget> children, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Flex(
    direction: direction,
    children: [for (final child in children) Expanded(child: child)],
  );
}

class const ExpandedFlexExpanded(final Axis direction, final List<Widget> children, {/* flexfactor */ super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Flex(
      direction: direction,
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}

class const Grid4(final Widget upperLeft, final Widget upperRight, final Widget lowerLeft, final Widget lowerRight, {super.key}) extends StatelessWidget {
  Grid4.list(List<Widget> children, {Key? key}) : this(children[0], children[1], children[2], children[3], key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpandedRowExpanded([upperLeft, upperRight]),
        ExpandedRowExpanded([lowerLeft, lowerRight]),
      ],
    );
    // return Flex(children: [
    //   ExpandedFlexExpanded([upperLeft, upperRight]),
    //   ExpandedFlexExpanded([lowerLeft, lowerRight])
    // ]);
  }
}

class const Grid3(final Widget half, final Widget quarter1, final Widget quarter2, {final Axis direction = Axis.horizontal, final bool isHalfLeading = true, super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      // todo select if half is first top/left
      children: [
        ExpandedFlexExpanded(flipAxis(direction), [half]),
        ExpandedFlexExpanded(flipAxis(direction), [quarter1, quarter2]),
      ],
    );
  }
}

class const Grid2(final Widget half1, final Widget half2, {final Axis direction = Axis.horizontal, super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FlexExpanded(direction, [half1, half2]);
}

class const ExpandedCard(final Widget child, {final int flex = 1, super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: child),
      ),
    ),
  );
}

class const Grid6({
    required final Widget leftPanel,
    required final Widget rightPanel,
    required final Widget bottomLeftLeft,
    required final Widget bottomLeftCenter,
    required final Widget bottomRightCenter,
    required final Widget bottomRightRight,
    super.key,
  }) extends StatelessWidget {
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
