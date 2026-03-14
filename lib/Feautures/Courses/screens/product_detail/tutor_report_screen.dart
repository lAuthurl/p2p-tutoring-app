// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';

class TutorReportScreen extends StatefulWidget {
  final String tutorName;
  const TutorReportScreen({super.key, required this.tutorName});

  @override
  State<TutorReportScreen> createState() => _TutorReportScreenState();
}

class _TutorReportScreenState extends State<TutorReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();

  String? _selectedReason;
  bool _submitting = false;
  bool _submitted = false;

  static const _reasons = [
    'Inappropriate behaviour',
    'Misleading credentials',
    'Harassment or abuse',
    'Fraud or scam',
    'No-show / ghosting',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      Get.snackbar(
        'Missing field',
        'Please select a reason',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simulate network
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F14) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Report Tutor',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _submitted
              ? _SuccessView(tutorName: widget.tutorName)
              : _buildForm(isDark),
    );
  }

  Widget _buildForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reports are reviewed within 48 hours. Submitting false reports may result in your account being suspended.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color:
                            isDark
                                ? Colors.amber.shade100
                                : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tutor label
            Text(
              'Reporting',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.tutorName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 28),

            // Reason label
            _Label(text: 'Reason for report'),
            const SizedBox(height: 10),
            ..._reasons.map(
              (reason) => _ReasonOption(
                label: reason,
                selected: _selectedReason == reason,
                onTap: () => setState(() => _selectedReason = reason),
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 24),

            // Details
            _Label(text: 'Additional details'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _detailsController,
              maxLines: 5,
              maxLength: 500,
              validator:
                  (v) =>
                      v == null || v.trim().length < 10
                          ? 'Please provide at least 10 characters'
                          : null,
              decoration: InputDecoration(
                hintText:
                    'Describe what happened in as much detail as possible...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 14,
                ),
                filled: true,
                fillColor:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: TColors.primary, width: 1.5),
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.redAccent.withValues(
                    alpha: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success View ─────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String tutorName;
  const _SuccessView({required this.tutorName});

  @override
  Widget build(BuildContext context) {
    // Pop back to profile and return the selected reason
    // Use addPostFrameCallback so it happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.findAncestorStateOfType<_TutorReportScreenState>();
      if (state != null) {
        Future.delayed(const Duration(seconds: 2), () {
          Get.back(result: state._selectedReason ?? 'Reported conduct');
        });
      }
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.redAccent,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Report Submitted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you. Your report about $tutorName has been received and will be reviewed within 48 hours.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Returning to profile...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reason Option ─────────────────────────────────────────────────────────────
class _ReasonOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.redAccent.withValues(alpha: 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? Colors.redAccent.withValues(alpha: 0.6)
                    : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.redAccent : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.redAccent : Colors.grey,
                  width: 1.5,
                ),
              ),
              child:
                  selected
                      ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
                color:
                    selected
                        ? Colors.redAccent
                        : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Label ────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: -0.1,
      ),
    );
  }
}
