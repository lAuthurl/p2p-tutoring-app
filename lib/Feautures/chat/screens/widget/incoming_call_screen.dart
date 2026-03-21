import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../controllers/call.dart';

class IncomingCallScreen extends StatelessWidget {
  final TCallSession callSession;
  const IncomingCallScreen({super.key, required this.callSession});

  @override
  Widget build(BuildContext context) {
    final ctrl = CallController.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2E),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Caller info ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white12,
                    child: Text(
                      callSession.callerId.isNotEmpty
                          ? callSession.callerId[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    callSession.callerId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    callSession.isVideo
                        ? 'Incoming video call...'
                        : 'Incoming voice call...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // ── Accept / Reject buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.call_end_rounded,
                    label: 'Decline',
                    color: Colors.red,
                    onTap: () => ctrl.rejectCall(callSession),
                  ),
                  _ActionButton(
                    icon:
                        callSession.isVideo
                            ? Iconsax.video
                            : Icons.call_rounded,
                    label: 'Accept',
                    color: Colors.green,
                    onTap: () => ctrl.acceptCall(callSession),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
