// ignore_for_file: public_member_api_docs, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';
import '../../controllers/tutoring_controller.dart';

class TutorProfileScreen extends StatefulWidget {
  final Tutor tutor;

  const TutorProfileScreen({super.key, required this.tutor});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final TutoringController _tutoringController = Get.find();

  List<Review> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchTutorReviews();
  }

  Future<void> _fetchTutorReviews() async {
    try {
      final reviews = await _tutoringController.fetchReviewsByTutor(
        widget.tutor.id,
      );
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (e) {
      print('❌ Error fetching tutor reviews: $e');
      setState(() => _loadingReviews = false);
    }
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<double>(0, (sum, r) => sum + (r.rating));
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final aboutText =
        widget.tutor.about?.isNotEmpty == true
            ? widget.tutor.about!
            : "No information provided by this tutor.";

    final skillsList =
        widget.tutor.skills?.isNotEmpty == true
            ? widget.tutor.skills!
            : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text("Tutor Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Card
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: TColors.primary,
                    backgroundImage:
                        widget.tutor.image != null &&
                                widget.tutor.image!.isNotEmpty
                            ? NetworkImage(widget.tutor.image!)
                            : null,
                    child:
                        (widget.tutor.image == null ||
                                widget.tutor.image!.isEmpty)
                            ? Text(
                              widget.tutor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tutor.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.tutor.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),

                        /// Rating Summary
                        _loadingReviews
                            ? const SizedBox(
                              height: 20,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : Row(
                              children: [
                                RatingBarIndicator(
                                  rating: averageRating,
                                  itemBuilder:
                                      (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                  itemCount: 5,
                                  itemSize: 20,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _reviews.isNotEmpty
                                      ? "${averageRating.toStringAsFixed(1)} (${_reviews.length} reviews)"
                                      : "No reviews yet",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// About Section
            const TSectionHeading(title: "About", showActionButton: false),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(aboutText),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Skills Section
            const TSectionHeading(title: "Skills", showActionButton: false),
            const SizedBox(height: TSizes.spaceBtwItems),
            skillsList.isNotEmpty
                ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skillsList
                          .map((skill) => Chip(label: Text(skill)))
                          .toList(),
                )
                : const Text("No skills added yet."),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Reviews Section
            const TSectionHeading(title: "Reviews", showActionButton: false),
            const SizedBox(height: TSizes.spaceBtwItems),
            _loadingReviews
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Text("No reviews yet.")
                : Column(
                  children:
                      _reviews.map((review) {
                        final date = DateFormat.yMMMd().format(
                          review.createdAt!.getDateTimeInUtc(),
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: TSizes.spaceBtwItems / 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(TSizes.defaultSpace),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          review.user?.profilePicture != null &&
                                                  review
                                                      .user!
                                                      .profilePicture!
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                review.user!.profilePicture!,
                                              )
                                              : null,
                                      backgroundColor: TColors.primary,
                                      child:
                                          (review.user?.profilePicture ==
                                                      null ||
                                                  review
                                                      .user!
                                                      .profilePicture!
                                                      .isEmpty)
                                              ? Text(
                                                review.user?.username[0]
                                                        .toUpperCase() ??
                                                    "?",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        review.user?.username ?? "Anonymous",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        final iconColor =
                                            index < (review.rating).round()
                                                ? Colors.amber
                                                : Colors.grey.shade300;
                                        return Icon(
                                          Icons.star,
                                          color: iconColor,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(review.comment ?? ''),
                                if (date.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              padding: const EdgeInsets.all(TSizes.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Book Session"),
          ),
        ),
      ),
    );
  }
}
