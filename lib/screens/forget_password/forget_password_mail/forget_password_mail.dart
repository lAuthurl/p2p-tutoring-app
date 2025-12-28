import 'package:flutter/material.dart';

import '../../../../../../common/widgets/form/form_header_widget.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/image_strings.dart';
import '../../../../../../utils/constants/sizes.dart';
import '../../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import 'package:get/get.dart';
import '../../../../../../utils/popups/loaders.dart';
import '../../../../../../data/repository/authentication_repository/authentication_repository.dart';
import 'forget_password_confirm.dart';

class ForgetPasswordMailScreen extends StatelessWidget {
  const ForgetPasswordMailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //Just In-case if you want to replace the Image Color for Dark Theme
    final dark = THelperFunctions.isDarkMode(context);

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                const SizedBox(height: TSizes.defaultSpace * 4),
                FormHeaderWidget(
                  imageColor: dark ? TColors.primary : TColors.secondary,
                  image: TImages.tForgetPasswordImage,
                  title: TTexts.tForgetPasswordTitle,
                  subTitle: TTexts.tForgetPasswordSubTitle,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  heightBetween: 30.0,
                  textAlign: TextAlign.center,
                  imageHeight: 0.25,
                ),
                const SizedBox(height: TSizes.xl),
                _ForgetPasswordForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgetPasswordForm extends StatefulWidget {
  @override
  State<_ForgetPasswordForm> createState() => _ForgetPasswordFormState();
}

class _ForgetPasswordFormState extends State<_ForgetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _startReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Please enter your email',
      );
      return;
    }
    // basic validation
    if (!email.contains('@')) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Please enter a valid email',
      );
      return;
    }

    try {
      TLoaders.openLoading();
      await AuthenticationRepository.instance.resetPasswordStart(email);
      TLoaders.stopLoading();
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'A confirmation code has been sent to $email',
      );
      Get.to(() => ForgetPasswordConfirmScreen(email: email));
    } catch (e) {
      TLoaders.stopLoading();
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              label: Text(TTexts.tEmail),
              hintText: TTexts.tEmail,
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startReset,
              child: const Text(TTexts.tNext),
            ),
          ),
        ],
      ),
    );
  }
}
