import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../../data/repository/authentication_repository/authentication_repository.dart';

class ForgetPasswordConfirmScreen extends StatelessWidget {
  const ForgetPasswordConfirmScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();
    final passwordController = TextEditingController();

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                const SizedBox(height: TSizes.xl),
                Text(
                  TTexts.tResetPassword,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Enter the confirmation code sent to $email',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation Code',
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final code = codeController.text.trim();
                      final newPass = passwordController.text.trim();
                      if (code.isEmpty || newPass.isEmpty) {
                        TLoaders.errorSnackBar(
                          title: 'Error',
                          message: 'Please enter code and new password',
                        );
                        return;
                      }
                      TLoaders.openLoading();
                      try {
                        await AuthenticationRepository.instance
                            .resetPasswordConfirm(email, newPass, code);
                        TLoaders.stopLoading();
                        // Show confirmation dialog with a Go to Login button
                        await Get.dialog(
                          PopScope(
                            canPop: false,
                            child: AlertDialog(
                              title: const Text('Success'),
                              content: const Text(
                                'Password reset successful. Please login with your new password.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.offAllNamed('/log-in');
                                  },
                                  child: const Text('Go to Login'),
                                ),
                              ],
                            ),
                          ),
                          barrierDismissible: false,
                        );
                      } catch (e) {
                        TLoaders.stopLoading();
                        TLoaders.errorSnackBar(
                          title: 'Error',
                          message: e.toString(),
                        );
                      }
                    },
                    child: const Text(TTexts.tResetPassword),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
