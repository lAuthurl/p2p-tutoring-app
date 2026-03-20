// lib/utils/cache/session_access_cache.dart
//
// Caches the three expensive per-session lookups that fire on every
// SessionDetailScreen open:
//
//   1. isTutor(sessionId)      — whether the current user owns this session
//   2. hasPaid(sessionId)      — whether the current user has paid
//   3. reviews(sessionId)      — list of reviews for the session
//
// All entries carry a TTL and are keyed by (userId, sessionId) so
// switching accounts never serves stale data.
//
// Invalidation:
//   SessionAccessCache.instance.invalidatePayment(sessionId)  — call after checkout
//   SessionAccessCache.instance.invalidateReviews(sessionId)  — call after new review
//   SessionAccessCache.instance.clearAll()                    — call on logout

import 'package:flutter/foundation.dart';

class _Entry<T> {
  _Entry(this.value, this.ttlMinutes) : cachedAt = DateTime.now();
  final T value;
  final int ttlMinutes;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inMinutes >= ttlMinutes;
}

class SessionAccessCache {
  SessionAccessCache._();
  static final SessionAccessCache instance = SessionAccessCache._();

  // ── Tutor ownership cache ─────────────────────────────────────────────────
  // keyed by '$userId|$sessionId' — must include sessionId so visiting one
  // session as a tutor doesn't incorrectly mark ALL sessions as owned.
  // 60 min TTL — tutor ownership of a specific session never changes.
  final Map<String, _Entry<bool>> _isTutorCache = {};

  // ── Payment status cache ──────────────────────────────────────────────────
  // keyed by '$userId|$sessionId' — 10 min TTL, invalidated after checkout
  final Map<String, _Entry<bool>> _paymentCache = {};

  // ── Reviews cache ─────────────────────────────────────────────────────────
  // keyed by sessionId — 5 min TTL, invalidated after new review submitted
  // Value is List<dynamic> — stored as-is, cast by caller
  final Map<String, _Entry<List<dynamic>>> _reviewsCache = {};

  // ── In-flight dedup ───────────────────────────────────────────────────────
  final Map<String, Future<bool>> _pendingTutor = {};
  final Map<String, Future<bool>> _pendingPayment = {};

  // =========================================================================
  // TUTOR CHECK
  // =========================================================================

  /// Returns true if [userId] is the tutor for [sessionId] via [fetcher].
  /// Keyed by userId|sessionId — visiting one session as a tutor must not
  /// bleed ownership onto other sessions the same user doesn't own.
  Future<bool> getIsTutor({
    required String userId,
    required String sessionId,
    required Future<bool> Function() fetcher,
  }) async {
    // KEY FIX: include sessionId so each session gets its own ownership result
    final key = '$userId|$sessionId';

    final cached = _isTutorCache[key];
    if (cached != null && !cached.isExpired) return cached.value;

    if (_pendingTutor.containsKey(key)) return _pendingTutor[key]!;

    final future = fetcher().then((v) {
      _isTutorCache[key] = _Entry(v, 60);
      _pendingTutor.remove(key);
      return v;
    });
    _pendingTutor[key] = future;
    return future;
  }

  // =========================================================================
  // PAYMENT CHECK
  // =========================================================================

  /// Returns true if [userId] has paid for [sessionId] via [fetcher].
  /// Cached for 10 minutes. Call [invalidatePayment] after checkout succeeds.
  Future<bool> getHasPaid({
    required String userId,
    required String sessionId,
    required Future<bool> Function() fetcher,
  }) async {
    final key = '$userId|$sessionId';

    final cached = _paymentCache[key];
    if (cached != null && !cached.isExpired) return cached.value;

    if (_pendingPayment.containsKey(key)) return _pendingPayment[key]!;

    final future = fetcher().then((v) {
      _paymentCache[key] = _Entry(v, 10);
      _pendingPayment.remove(key);
      return v;
    });
    _pendingPayment[key] = future;
    return future;
  }

  /// Force re-fetch on next [getHasPaid] call for this session.
  /// Call this immediately after a successful checkout.
  void invalidatePayment(String sessionId) {
    _paymentCache.removeWhere((k, _) => k.contains('|$sessionId'));
    debugPrint('🗑 SessionAccessCache: payment cache cleared for $sessionId');
  }

  // =========================================================================
  // REVIEWS
  // =========================================================================

  /// Returns cached reviews or fetches via [fetcher].
  /// Cached for 5 minutes. Call [invalidateReviews] after a new review.
  Future<List<T>> getReviews<T>({
    required String sessionId,
    required Future<List<T>> Function() fetcher,
  }) async {
    final cached = _reviewsCache[sessionId];
    if (cached != null && !cached.isExpired) {
      return List<T>.from(cached.value);
    }

    final fresh = await fetcher();
    _reviewsCache[sessionId] = _Entry(fresh, 5);
    return fresh;
  }

  /// Force re-fetch on next [getReviews] call for this session.
  void invalidateReviews(String sessionId) {
    _reviewsCache.remove(sessionId);
    debugPrint('🗑 SessionAccessCache: reviews cache cleared for $sessionId');
  }

  // =========================================================================
  // LOGOUT CLEANUP
  // =========================================================================

  void clearAll() {
    _isTutorCache.clear();
    _paymentCache.clear();
    _reviewsCache.clear();
    _pendingTutor.clear();
    _pendingPayment.clear();
    debugPrint('🗑 SessionAccessCache: all caches cleared');
  }
}
