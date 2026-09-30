import 'package:flutter/material.dart';
import 'chart_controller.dart';
import 'chart_style.dart';

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.listenable, required this.entries, this.style, this.builder});
  ChartLegend.of({super.key, required ChartController controller, this.style, this.builder})
      : entries = controller.chartEntries,
        listenable = controller;

  final List<ChartEntry> entries;
  final Listenable listenable; // update on controller tick
  final Widget Function(BuildContext context, ChartEntry entry, Widget entryWidget)? builder; // optional wrapper for legend entry
  final ChartStyle? style;

  Widget legendEntryWidget(BuildContext context, ChartEntry entry, int styleIndex) {
    final effectiveColor = entry.color ?? style?.legendColor(styleIndex) ?? const ChartStyleDefault().legendColor(styleIndex) ?? Colors.white;
    final effectiveTextStyle = style?.legendTextStyle ?? const ChartStyleDefault().legendTextStyle.copyWith(color: effectiveColor);

    final listTile = _LegendListTile(
      listenable: listenable,
      name: entry.name,
      valueGetter: entry.valueGetter,
      color: effectiveColor,
      textStyle: effectiveTextStyle,
      onSelect: entry.onSelect,
      // isSelected: valuesSelected?[index] ?? false,
    );
    return builder?.call(context, entry, listTile) ?? listTile;
  }

  @override
  Widget build(BuildContext context) {
    // return IntrinsicHeight(
    //   child: ListView(
    //     padding: EdgeInsets.zero,
    //     shrinkWrap: true,
    //     prototypeItem: legendEntryWidget(entries[0], 0),
    //     children: [for (final (index, entry) in entries.indexed) legendEntryWidget(entry, index)],
    //   ),
    // );
    return Column(
      children: [for (final (index, entry) in entries.indexed) legendEntryWidget(context, entry, index)],
    );
  }
}

class const _LegendListTile({
    required final Listenable listenable,
    required final String name,
    required final Color color,
    required final ValueGetter<num> valueGetter,
    final void Function()? onSelect,
    final TextStyle? textStyle,
    // this.isSelected = false,
  }) extends StatelessWidget {
  // final bool isSelected;

  Widget builder(context, child) => Text(valueGetter().toStringAsFixed(1), textAlign: TextAlign.right, style: textStyle);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onSelect,
      dense: true,
      leading: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const SizedBox.square(dimension: 15)),
      title: Text(name, style: textStyle),
      trailing: ListenableBuilder(listenable: listenable, builder: builder),
    );
  }
}

// class AnimatedLegend extends StatelessWidget {
//   const AnimatedLegend({super.key, this.onSelect, required this.isSelected});
//   final Function()? onSelect;
//   final bool isSelected;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       // onTap: () => onSelect,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         margin: const EdgeInsets.symmetric(vertical: 2),
//         height: 26,
//         decoration: BoxDecoration(
//           // color: isSelected ? AppColors.pageBackground : Colors.transparent,
//           color: Colors.transparent,
//           borderRadius: BorderRadius.circular(46),
//         ),
//         padding: const EdgeInsets.symmetric(
//           vertical: 4,
//           horizontal: 6,
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 400),
//               curve: Curves.easeInToLinear,
//               padding: EdgeInsets.all(isSelected ? 8 : 6),
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 8),
//             AnimatedDefaultTextStyle(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInToLinear,
//               style: TextStyle(
//                 color: isSelected ? color : Colors.white70,
//               ),
//               child: Text(name),
//             ),
//             // const Spacer(),
//             Text(obsVar.value.toStringAsFixed(1), style: TextStyle(color: color)) ,
//           ],
//         ),
//       ),
//     );
//   }
// }
