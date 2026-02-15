import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../../../../common/widgets/custom_shapes/containers/circular_container.dart';
import '../../../../../../common/widgets/images/t_rounded_image.dart';
import '../../../../../../utils/constants/sizes.dart';

/// -- Carousel slider for promotional banners (e.g., upcoming lectures, events)
class TPromoSlider extends StatefulWidget {
  const TPromoSlider({super.key, required this.banners});

  final List<String> banners;

  @override
  State<TPromoSlider> createState() => _TPromoSliderState();
}

class _TPromoSliderState extends State<TPromoSlider> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache banner images to avoid visual lag when carousel advances
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

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            pauseAutoPlayOnTouch: true,
            enableInfiniteScroll: true,
            onPageChanged: (index, _) => setState(() => _currentIndex = index),
          ),
          items:
              widget.banners
                  .map(
                    (url) => TRoundedImage(
                      imageUrl: url,
                      backgroundColor: Colors.transparent,
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.banners.length; i++)
                GestureDetector(
                  onTap: () => _carouselController.animateToPage(i),
                  child: TCircularContainer(
                    width: 20,
                    height: 4,
                    margin: const EdgeInsets.only(right: 10),
                    backgroundColor:
                        _currentIndex == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.12),
                    y: 0,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
