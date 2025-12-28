import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../authentication/controllers/verify_email_controller.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerifyEmailController>();
    final TextEditingController codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A verification code was sent to:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.confirmCode(
                    email,
                    codeController.text.trim(),
                  );
                },
                child: const Text('Confirm Code'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => controller.resendCode(email),
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
