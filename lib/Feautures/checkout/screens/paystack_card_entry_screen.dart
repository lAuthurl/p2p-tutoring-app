// lib/Features/checkout/screens/paystack_card_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/paystack_card_controller.dart';

class PaystackCardEntryScreen extends StatelessWidget {
  const PaystackCardEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PaystackCardController());
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Add Payment Card',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: ctrl.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Paystack header banner ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C3F7), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0BA4DB).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secured by Paystack',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your card details are encrypted & never stored in plain text.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Card number ────────────────────────────────────────
              _FieldLabel(label: 'Card Number', theme: theme, cs: cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: ctrl.cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                decoration: _inputDecoration(
                  cs: cs,
                  hint: '0000  0000  0000  0000',
                  prefix: const Icon(Icons.credit_card_outlined, size: 20),
                ),
                style: const TextStyle(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
                validator: (v) {
                  final n = (v ?? '').replaceAll(' ', '');
                  if (n.length < 16) return 'Enter a valid 16-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Cardholder name ────────────────────────────────────
              _FieldLabel(label: 'Cardholder Name', theme: theme, cs: cs),
              const SizedBox(height: 8),
              TextFormField(
                controller: ctrl.cardholderController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  cs: cs,
                  hint: 'Full name as on card',
                  prefix: const Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Cardholder name is required'
                            : null,
              ),
              const SizedBox(height: 18),

              // ── Expiry + CVV ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Expiry Date', theme: theme, cs: cs),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrl.expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_ExpiryFormatter()],
                          decoration: _inputDecoration(
                            cs: cs,
                            hint: 'MM / YY',
                            prefix: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 5) {
                              return 'Invalid expiry';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'CVV', theme: theme, cs: cs),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrl.cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: _inputDecoration(
                            cs: cs,
                            hint: '• • •',
                            prefix: const Icon(Icons.lock_outline, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 3) {
                              return 'Invalid CVV';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────
              Obx(() {
                final saving = ctrl.isSaving.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        saving
                            ? null
                            : () async {
                              final ok = await ctrl.saveCard();
                              if (ok) {
                                Get.back();
                                Get.snackbar(
                                  '✅ Card Saved',
                                  '${ctrl.savedCard.value.cardType} ${ctrl.savedCard.value.maskedNumber} is ready for checkout',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0BA4DB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF0BA4DB,
                      ).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child:
                        saving
                            ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Securing card…',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Card Securely',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  '🔒  256-bit SSL  ·  PCI DSS Level 1 Compliant',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme cs,
    required String hint,
    required Widget prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0BA4DB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.theme,
    required this.cs,
  });

  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withValues(alpha: 0.75),
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 16) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (digits.length > 4) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write(' / ');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
