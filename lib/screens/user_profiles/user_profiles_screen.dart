import 'package:flutter/material.dart';

class UserProfilesScreen extends StatelessWidget {
  const UserProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'User Profiles',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    );
  }
}
