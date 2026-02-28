// ignore_for_file: public_member_api_docs, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../models/ModelProvider.dart';
import '../../controllers/tutoring_controller.dart';

class SessionReviewScreen extends StatefulWidget {
  final TutoringSession session;

  const SessionReviewScreen({super.key, required this.session});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  final TutoringController _tutoringController = Get.find();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;

  late TutoringSession _currentSession; // <-- mutable copy
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session; // initialize local session
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _loading = true);
    try {
      final reviews = await _tutoringController.fetchReviews(
        _currentSession.id,
      );
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch reviews",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _commentController.text.trim().isEmpty) {
      Get.snackbar(
        "Incomplete",
        "Please provide a rating and a comment",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Ensure the session has a tutor
      if (_currentSession.tutor == null) {
        final tutorId = _currentSession.tutor?.id;
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutors = await Amplify.DataStore.query(
            Tutor.classType,
            where: Tutor.ID.eq(tutorId),
          );
          if (tutors.isNotEmpty) {
            _currentSession = _currentSession.copyWith(tutor: tutors.first);
          } else {
            throw Exception("Tutor not found");
          }
        } else {
          throw Exception("Session has no tutor assigned");
        }
      }

      final newReview = await _tutoringController.addReview(
        session: _currentSession,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      setState(() {
        _reviews.insert(0, newReview);
        _rating = 0;
        _commentController.clear();
      });

      Get.snackbar(
        "Success",
        "Review submitted successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      // Return to previous screen and signal update
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to submit review: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average rating
                    _reviews.isNotEmpty
                        ? Row(
                          children: [
                            RatingBarIndicator(
                              rating:
                                  _reviews.fold<double>(
                                    0,
                                    (sum, r) => sum + (r.rating ?? 0),
                                  ) /
                                  _reviews.length,
                              itemBuilder:
                                  (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                              itemCount: 5,
                              itemSize: 24,
                              direction: Axis.horizontal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${_reviews.length} reviews)",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                        : const Text("No reviews yet"),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Leave a review
                    const TSectionHeading(
                      title: "Leave a Review",
                      showActionButton: false,
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 32,
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate:
                          (rating) => setState(() => _rating = rating),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write your comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: TColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems / 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Submit Review",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // All reviews list
                    const TSectionHeading(
                      title: "All Reviews",
                      showActionButton: false,
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    ..._reviews.map((review) => _buildReviewTile(review)),
                  ],
                ),
              ),
    );
  }

  Widget _buildReviewTile(Review review) {
    final date = DateFormat.yMMMd().format(
      review.createdAt!.getDateTimeInUtc(),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              review.user!.profilePicture!.isNotEmpty
                          ? NetworkImage(review.user!.profilePicture!)
                          : null,
                  backgroundColor: TColors.primary,
                  child:
                      (review.user?.profilePicture == null ||
                              review.user!.profilePicture!.isEmpty)
                          ? Text(
                            review.user?.username[0].toUpperCase() ?? "?",
                            style: const TextStyle(color: Colors.white),
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.user?.username ?? "Anonymous",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final iconColor =
                        index < (review.rating ?? 0).round()
                            ? Colors.amber
                            : Colors.grey.shade300;
                    return Icon(Icons.star, color: iconColor, size: 16);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment ?? ''),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
