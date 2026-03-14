import 'package:flutter/material.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../models/model_on_boarding.dart';

class OnBoardingPageWidget extends StatelessWidget {
  const OnBoardingPageWidget({
    super.key,
    required this.model,
    this.onUserInteraction,
  });

  final OnBoardingModel model;
  final VoidCallback? onUserInteraction;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onUserInteraction,
      onHorizontalDragStart: (_) => onUserInteraction?.call(),
      child: Container(
        color: model.bgColor,
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Image ───────────────────────────────────────────
            SizedBox(
              width: size.width * 0.75,
              height: size.width * 0.75,
              child: Image.asset(
                model.image,
                fit: BoxFit.contain,
                cacheWidth: 500,
                cacheHeight: 500,
              ),
            ),

            const SizedBox(height: 40),

            // ── Counter pill ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                model.counterText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────
            Text(
              model.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            // ── Subtitle ─────────────────────────────────────────
            Text(
              model.subTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black.withValues(alpha: 0.55),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
