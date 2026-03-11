// lib/Feautures/Chat/screens/inbox_screen.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../utils/constants/sizes.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Iconsax.setting_4)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: 5, // Replace with dynamic count from a controller
        separatorBuilder:
            (_, __) => const SizedBox(height: TSizes.spaceBtwItems),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage('assets/images/profile/user.png'),
            ),
            title: Text(
              'Tutor Name ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: const Text(
              'Hello! Are we still meeting for the Math session?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('12:45 PM', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                if (index == 0) // Example unread badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to specific chat room
            },
          );
        },
      ),
    );
  }
}
