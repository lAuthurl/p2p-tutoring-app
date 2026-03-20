// lib/utils/cache/image_cache_service.dart
//
// Shared image URL cache used by TNetworkImage and TUserAvatar.
//
// Two-layer cache:
//   1. In-memory map  — zero-latency hits for the current session
//   2. Disk cache     — persists across restarts via cached_network_image
//      (the disk layer is handled by CachedNetworkImage itself; this service
//       only manages the URL resolution layer on top of it)
//
// Pre-signed S3 URLs expire after ~15 minutes. We store the resolved URL
// with a timestamp and re-fetch only when it is close to expiry.
//
// Usage:
//   final url = await ImageCacheService.instance.resolve(rawKeyOrUrl);

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

class _CachedUrl {
  _CachedUrl(this.url) : resolvedAt = DateTime.now();
  final String url;
  final DateTime resolvedAt;

  // Re-resolve 2 minutes before the typical 15-minute S3 expiry
  bool get isExpired => DateTime.now().difference(resolvedAt).inMinutes >= 13;
}

class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService instance = ImageCacheService._();

  // key: raw S3 key or original URL  →  value: cached resolved URL + timestamp
  final Map<String, _CachedUrl> _cache = {};

  // In-flight futures — prevents multiple simultaneous resolves for the same key
  final Map<String, Future<String?>> _pending = {};

  /// Returns a resolved, non-expired URL for [rawKeyOrUrl].
  /// Returns null if resolution fails.
  Future<String?> resolve(String? rawKeyOrUrl) async {
    if (rawKeyOrUrl == null || rawKeyOrUrl.isEmpty) return null;

    // 1. Full URL that is NOT an S3 pre-signed URL — use as-is forever
    if (_isExternalUrl(rawKeyOrUrl)) return rawKeyOrUrl;

    // 2. Check in-memory cache
    final cached = _cache[rawKeyOrUrl];
    if (cached != null && !cached.isExpired) return cached.url;

    // 3. Deduplicate concurrent requests for the same key
    if (_pending.containsKey(rawKeyOrUrl)) {
      return _pending[rawKeyOrUrl];
    }

    // 4. Resolve fresh URL
    final future = _resolveFromAmplify(rawKeyOrUrl);
    _pending[rawKeyOrUrl] = future;

    try {
      final url = await future;
      if (url != null) {
        _cache[rawKeyOrUrl] = _CachedUrl(url);
      }
      return url;
    } finally {
      _pending.remove(rawKeyOrUrl);
    }
  }

  /// Invalidates the cache entry for [rawKeyOrUrl].
  /// Call this when a user updates their profile picture.
  void invalidate(String rawKeyOrUrl) {
    _cache.remove(rawKeyOrUrl);
  }

  /// Clears the entire cache — call on logout.
  void clear() {
    _cache.clear();
    _pending.clear();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  bool _isExternalUrl(String s) {
    if (!s.startsWith('http://') && !s.startsWith('https://')) return false;
    // S3 pre-signed URLs contain X-Amz-Signature — treat as S3 keys
    // (they expire and must be refreshed via Amplify Storage)
    if (s.contains('X-Amz-Signature') || s.contains('x-amz-signature')) {
      return false;
    }
    return true;
  }

  Future<String?> _resolveFromAmplify(String key) async {
    // Strip leading slash if present
    final cleanKey = key.startsWith('/') ? key.substring(1) : key;

    // If it looks like a full S3 URL (but pre-signed), extract the path
    final s3Key = _extractS3Key(cleanKey);

    try {
      final result =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(s3Key),
          ).result;
      return result.url.toString();
    } catch (e) {
      debugPrint('⚠️ ImageCacheService._resolveFromAmplify($s3Key): $e');
      return null;
    }
  }

  String _extractS3Key(String raw) {
    // If it's a full URL, extract just the path component
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      try {
        final uri = Uri.parse(raw);
        final path =
            uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return path.isNotEmpty ? path : raw;
      } catch (_) {}
    }
    return raw;
  }
}
