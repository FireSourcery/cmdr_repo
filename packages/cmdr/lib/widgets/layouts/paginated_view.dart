import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PaginatedView extends StatefulWidget {
  const PaginatedView({required this.children, this.controller, this.pageController, this.tabController, this.scrollBehavior, super.key});
  final List<Widget> children;
  final PageController? pageController;
  final TabController? tabController;
  final ScrollBehavior? scrollBehavior;
  final ScrollController? controller;

  @override
  State<PaginatedView> createState() => _PaginatedViewState();
}

class _PaginatedViewState extends State<PaginatedView> with SingleTickerProviderStateMixin {
  final PageController _pageViewController = PageController();
  late final TabController _tabController = TabController(length: widget.children.length, vsync: this);

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    // if (!_isOnDesktopAndWeb) return;

    // _tabController.index = currentPageIndex;
    // setState(() {
    //   _currentPageIndex = currentPageIndex;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      // alignment: Alignment.bottomCenter,
      children: <Widget>[
        Expanded(
          child: PageView(
            scrollBehavior: _DefaultScrollBehavior(),
            controller: _pageViewController,
            onPageChanged: _handlePageViewChanged,
            children: widget.children,
          ),
        ),
        const SizedBox(height: 5),
        TabPageSelector(controller: _tabController, color: colorScheme.surface, selectedColor: colorScheme.primary),
      ],
    );
  }
}

class _DefaultScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse};
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.tabController, required this.currentPageIndex, required this.onUpdateCurrentPageIndex, required this.isOnDesktopAndWeb});

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  final bool isOnDesktopAndWeb;

  @override
  Widget build(BuildContext context) {
    if (!isOnDesktopAndWeb) return const SizedBox.shrink();

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            splashRadius: 16.0,
            padding: EdgeInsets.zero,
            onPressed: () {
              if (currentPageIndex == 0) return;
              onUpdateCurrentPageIndex(currentPageIndex - 1);
            },
            icon: const Icon(Icons.arrow_left_rounded, size: 32.0),
          ),
          TabPageSelector(controller: tabController, color: colorScheme.surface, selectedColor: colorScheme.primary),
          IconButton(
            splashRadius: 16.0,
            padding: EdgeInsets.zero,
            onPressed: () {
              if (currentPageIndex == 2) return;
              onUpdateCurrentPageIndex(currentPageIndex + 1);
            },
            icon: const Icon(Icons.arrow_right_rounded, size: 32.0),
          ),
        ],
      ),
    );
  }
}
