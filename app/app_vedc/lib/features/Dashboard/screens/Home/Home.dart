import 'package:app_vedc/features/Dashboard/screens/HealthCare/HealthCare.dart';
import 'package:app_vedc/features/Dashboard/screens/Home/deviceUser.dart';
import 'package:app_vedc/features/Dashboard/screens/User/onUsers.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Home dashboard shell with curved bottom navigation and persistent pages.
class OnHome extends StatefulWidget {
  const OnHome({super.key});

  @override
  State<OnHome> createState() => _OnHomeState();
}

class _OnHomeState extends State<OnHome> {
  static const _iconPaths = [
    'assets/icons/Normals/home.svg',
    'assets/icons/Normals/calib.svg',
    'assets/icons/Normals/user.svg',
  ];

  static const _navAnimation = Duration(milliseconds: 400);

  late final List<Widget> _pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = const [OnDeviceUser(), OnHealthCare(), OnUsers()];
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildIcon(String path, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SvgPicture.asset(
        path,
        width: 26,
        height: 26,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = VedcColors.background;
    final primary = VedcColors.primary;
    final iconColor = VedcColors.white;

    final navItems = _iconPaths
        .map((path) => _buildIcon(path, iconColor))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CurvedNavigationBar(
        items: navItems,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: _navAnimation,
        color: primary,
        buttonBackgroundColor: primary,
        backgroundColor: background,
        onTap: _onNavTap,
        index: _currentIndex,
      ),
    );
  }
}
