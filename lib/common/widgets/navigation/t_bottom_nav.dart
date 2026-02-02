import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const TBottomNav({super.key, this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap:
          onTap ??
          (index) {
            switch (index) {
              case 0:
                Get.offAllNamed('/home');
                break;
              case 1:
                Get.toNamed('/browse');
                break;
              case 2:
                Get.toNamed('/messages');
                break;
              case 3:
                Get.toNamed('/profile');
                break;
            }
          },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
