// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key, required this.onTabChanged}) : super(key: key);

  final ValueChanged<int> onTabChanged;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late int currentIndex;

  final labels = [
    'Home',
    'Explore',
    'Pool',
    // "Favorites",
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      animationDuration: const Duration(milliseconds: 300),
      height: 60,
      //TODO: shouldn't use hardcode value, not working great when using multiple themes
      color: Colors.black,
      backgroundColor: Colors.transparent,
      items: const [
        FaIcon(FontAwesomeIcons.house),
        FaIcon(Icons.explore),
        FaIcon(FontAwesomeIcons.images),
      ],
      onTap: changePage,
    );
  }
}
