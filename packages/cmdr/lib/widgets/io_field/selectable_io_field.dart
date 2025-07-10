// class SelectableIOField<T> extends StatefulWidget {
//   const SelectableIOField({this.initialItem, super.key, required this.menuSource, required this.builder});

//   final FlyweightMenuSource<T> menuSource;
//   final T? initialItem;
//   // final ValueWidgetBuilder<T> builder;
//   // final ValueWidgetBuilder<T> builder;
//   final IOFieldConfig Function(T key) configBuilder;
//   // final Widget? child;

//   Widget effectiveBuilder(BuildContext context, T key, Widget? child) {
//     return IOField(configBuilder(key));
//   }

//   @override
//   State<SelectableIOField<T>> createState() => _SelectableIOFieldState<T>();
// }

// class _SelectableIOFieldState<T> extends State<SelectableIOField<T>> {
//   late final FlyweightMenu<T> menu = widget.menuSource.create(initialValue: widget.initialItem /*  onPressed: widget.onPressed */);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         FlyweightMenuButton<T>(menu: menu),
//         const VerticalDivider(thickness: 0, color: Colors.transparent),
//         // config rebuilds on varNotifier select update
//         Expanded(child: FlyweightMenuListenableBuilder<T>(menu: menu, builder: widget.effectiveBuilder)),
//       ],
//     );

//     // return ListTile(
//     //   // dense: true,
//     //   leading: menuSource.toButton(),
//     //   title: menuSource.contain((_, __) => _VarIOFieldBuilder.options(selectController.varNotifier, showLabel: true, isDense: false, showPrefix: true, showSuffix: true)),
//     // );
//   }
// }
