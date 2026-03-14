import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../../utils/constants/colors.dart';
import '../../../../../../utils/constants/sizes.dart';

class TPromoSlider extends StatefulWidget {
  const TPromoSlider({super.key, required this.banners});

  final List<String> banners;

  @override
  State<TPromoSlider> createState() => _TPromoSliderState();
}

class _TPromoSliderState extends State<TPromoSlider> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final url in widget.banners) {
      try {
        if (url.startsWith('http')) {
          precacheImage(NetworkImage(url), context);
        } else {
          precacheImage(AssetImage(url), context);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Carousel ──────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              viewportFraction: 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.easeInOut,
              pauseAutoPlayOnTouch: true,
              enableInfiniteScroll: true,
              onPageChanged:
                  (index, _) => setState(() => _currentIndex = index),
            ),
            items:
                widget.banners
                    .map(
                      (url) => TRoundedImage(
                        imageUrl: url,
                        backgroundColor: Colors.transparent,
                        borderRadius: 0,
                      ),
                    )
                    .toList(),
          ),
        ),

        // ── Dot indicators — overlaid bottom-centre ───────────────
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    width: isActive ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? TColors.dashboardAppbarBackground
                              : TColors.dashboardAppbarBackground.withValues(
                                alpha: 0.4,
                              ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Slide counter pill — top-right ────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TColors.dashboardAppbarBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.banners.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
