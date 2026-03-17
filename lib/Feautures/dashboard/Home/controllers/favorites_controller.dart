// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import '../../../../models/ModelProvider.dart';
import '../../../Courses/controllers/tutoring_controller.dart';
import 'home_controller.dart';

class FavoritesController extends GetxController {
  static FavoritesController get instance {
    if (Get.isRegistered<FavoritesController>()) return Get.find();
    return Get.put(FavoritesController(), permanent: true);
  }

  // ── Public state ──────────────────────────────────────────────────────────
  final favoriteIds = <String>{}.obs;
  final favoritedSessions = <TutoringSession>[].obs;
  final isLoading = false.obs;

  // ── Internal ──────────────────────────────────────────────────────────────
  final _records = <String, _FavRecord>{};

  // RxSet so Obx in TFavouriteIcon rebuilds when toggle starts/finishes.
  final _inProgress = <String>{}.obs;

  String? _currentUserId;
  Worker? _tutoringWorker;
  Worker? _homeWorker;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    _attachSessionWatchers();
  }

  @override
  void onClose() {
    _tutoringWorker?.dispose();
    _homeWorker?.dispose();
    super.onClose();
  }

  // =========================================================================
  // AUTO-WATCH
  // =========================================================================

  void _attachSessionWatchers() {
    _tutoringWorker?.dispose();
    _tutoringWorker = ever<List<TutoringSession>>(
      TutoringController.instance.sessions,
      (_) => _rehydrateFromExistingSources(),
    );
    _homeWorker?.dispose();
    if (Get.isRegistered<HomeController>()) {
      _homeWorker = ever<List<TutoringSession>>(
        HomeController.instance.allSessions,
        (_) => _rehydrateFromExistingSources(),
      );
    }
  }

  void _rehydrateFromExistingSources() {
    if (favoriteIds.isEmpty) return;

    final pool = <String, TutoringSession>{};
    try {
      for (final s in TutoringController.instance.sessions) {
        pool[s.id] = s;
      }
      for (final s in TutoringController.instance.activeSessions) {
        pool.putIfAbsent(s.id, () => s);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<HomeController>()) {
        for (final s in HomeController.instance.allSessions) {
          pool.putIfAbsent(s.id, () => s);
        }
      }
    } catch (_) {}

    if (pool.isEmpty) return;

    bool changed = false;
    final current = {for (final s in favoritedSessions) s.id: s};
    for (final id in favoriteIds) {
      final inPool = pool[id];
      if (inPool == null) continue;
      final existing = current[id];
      if (existing == null ||
          (existing.tutor?.name.isEmpty != false &&
              inPool.tutor?.name.isNotEmpty == true)) {
        current[id] = inPool;
        changed = true;
      }
    }
    if (changed) {
      favoritedSessions.assignAll(
        favoriteIds
            .where((id) => current.containsKey(id))
            .map((id) => current[id]!)
            .toList(),
      );
    }
  }

  // =========================================================================
  // VERSION PARSING
  // =========================================================================

  int? _parseVersion(String jsonStr, String operationKey) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final obj = root[operationKey] as Map<String, dynamic>?;
      if (obj != null) {
        final v = obj['_version'];
        if (v != null) return (v as num).toInt();
      }
    } catch (e) {
      print('⚠️ FavoritesController._parseVersion: $e');
    }
    return null;
  }

  // =========================================================================
  // AUTH
  // =========================================================================

  Future<String?> _getUserId({int retries = 3}) async {
    if (_currentUserId != null) return _currentUserId;
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final user = await Amplify.Auth.getCurrentUser();
        if (user.userId.isNotEmpty) {
          _currentUserId = user.userId;
          return _currentUserId;
        }
      } catch (_) {}
      if (attempt < retries - 1) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    return null;
  }

  // =========================================================================
  // LOAD
  // =========================================================================

  Future<void> _loadFavorites() async {
    final userId = await _getUserId();
    if (userId == null) return;

    isLoading.value = true;
    favoriteIds.clear();
    favoritedSessions.clear();
    _records.clear();

    try {
      const queryDoc = r"""
        query ListUserFavoritesByUser($userId: ID!, $limit: Int) {
          listUserFavoritesByUser(userId: $userId, limit: $limit) {
            items {
              id
              userId
              sessionId
              _version
              _deleted
            }
          }
        }
      """;

      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'userId': userId, 'limit': 1000},
                ),
              )
              .response;

      if (response.errors.isNotEmpty || response.data == null) {
        print('⚠️ FavoritesController: load failed — ${response.errors}');
        return;
      }

      _parseResponse(response.data!);
      _rehydrateFromExistingSources();
      await _hydrateMissingSessions();

      print(
        '✅ FavoritesController: loaded ${favoriteIds.length} active, '
        '${_records.length} total for user $userId',
      );
    } catch (e) {
      print('❌ FavoritesController._loadFavorites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _parseResponse(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final listObj = root['listUserFavoritesByUser'] as Map<String, dynamic>?;
      final items = listObj?['items'] as List<dynamic>? ?? [];

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'] as String?;
        final sessionId = item['sessionId'] as String?;
        final version = (item['_version'] as num?)?.toInt() ?? 1;
        final deleted = item['_deleted'] == true;

        if (id == null || sessionId == null) continue;

        _records[sessionId] = _FavRecord(
          id: id,
          version: version,
          isDeleted: deleted,
        );

        if (!deleted) favoriteIds.add(sessionId);
      }
    } catch (e) {
      print('❌ FavoritesController._parseResponse: $e');
    }
  }

  Future<void> _hydrateMissingSessions() async {
    final currentIds = favoritedSessions.map((s) => s.id).toSet();
    final missing =
        favoriteIds.where((id) => !currentIds.contains(id)).toList();
    if (missing.isEmpty) return;

    for (final sessionId in missing) {
      try {
        final local = await Amplify.DataStore.query(
          TutoringSession.classType,
          where: TutoringSession.ID.eq(sessionId),
        );
        if (local.isNotEmpty) {
          favoritedSessions.add(await _resolveSessionTutor(local.first));
          continue;
        }
        final remote = await _fetchSessionFromAppSync(sessionId);
        if (remote != null) favoritedSessions.add(remote);
      } catch (e) {
        print('⚠️ FavoritesController: could not hydrate $sessionId: $e');
      }
    }
  }

  Future<TutoringSession> _resolveSessionTutor(TutoringSession session) async {
    final tutorId = session.tutor?.id;
    if (tutorId == null || tutorId.isEmpty) return session;
    if (session.tutor?.name.isNotEmpty == true) return session;
    try {
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(tutorId),
      );
      if (tutors.isNotEmpty) return session.copyWith(tutor: tutors.first);
    } catch (_) {}
    return session;
  }

  Future<TutoringSession?> _fetchSessionFromAppSync(String sessionId) async {
    try {
      const queryDoc = r"""
        query GetTutoringSession($id: ID!) {
          getTutoringSession(id: $id) {
            id title description pricePerSession thumbnail
            tutorId isFeatured hasPaid createdAt updatedAt
          }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'id': sessionId},
                ),
              )
              .response;
      if (response.errors.isNotEmpty || response.data == null) return null;

      final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final data = root['getTutoringSession'] as Map<String, dynamic>?;
      if (data == null) return null;

      final tutorId = data['tutorId'] as String?;
      Tutor? tutor;
      if (tutorId != null && tutorId.isNotEmpty) {
        try {
          final tutors = await Amplify.DataStore.query(
            Tutor.classType,
            where: Tutor.ID.eq(tutorId),
          );
          if (tutors.isNotEmpty) tutor = tutors.first;
        } catch (_) {}
      }
      return TutoringSession(
        id: data['id'] as String,
        title: data['title'] as String? ?? 'Session',
        description: data['description'] as String?,
        pricePerSession: (data['pricePerSession'] as num?)?.toDouble(),
        thumbnail: data['thumbnail'] as String?,
        isFeatured: data['isFeatured'] as bool?,
        tutor: tutor,
      );
    } catch (e) {
      print('❌ FavoritesController._fetchSessionFromAppSync($sessionId): $e');
      return null;
    }
  }

  // =========================================================================
  // TOGGLE
  // =========================================================================

  Future<void> toggleFavorite(String sessionId) async {
    if (_inProgress.contains(sessionId)) return;

    final userId = await _getUserId();
    if (userId == null) return;

    _inProgress.add(sessionId);
    try {
      if (favoriteIds.contains(sessionId)) {
        await _removeFavorite(sessionId);
      } else {
        await _addFavorite(sessionId, userId);
      }
    } finally {
      _inProgress.remove(sessionId);
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> _addFavorite(String sessionId, String userId) async {
    favoriteIds.add(sessionId);
    await _addSessionToFavoritedList(sessionId);

    final existing = _records[sessionId];

    if (existing != null && !existing.isDeleted) {
      // Already active — nothing to do.
      print(
        '⚠️ FavoritesController: active record already exists for $sessionId',
      );
      return;
    }

    // Always create a fresh record — avoids all soft-delete version conflicts.
    if (existing != null && existing.isDeleted) {
      print(
        '🔄 FavoritesController: creating fresh record for $sessionId (old was soft-deleted)',
      );
    }
    await _createRecord(sessionId, userId);
  }

  Future<void> _addSessionToFavoritedList(String sessionId) async {
    if (favoritedSessions.any((s) => s.id == sessionId)) return;
    try {
      final local = await Amplify.DataStore.query(
        TutoringSession.classType,
        where: TutoringSession.ID.eq(sessionId),
      );
      if (local.isNotEmpty) {
        favoritedSessions.add(await _resolveSessionTutor(local.first));
        return;
      }
      final remote = await _fetchSessionFromAppSync(sessionId);
      if (remote != null) favoritedSessions.add(remote);
    } catch (e) {
      print('⚠️ FavoritesController._addSessionToFavoritedList: $e');
    }
  }

  Future<void> _createRecord(String sessionId, String userId) async {
    final recordId = amplify_core.UUID.getUUID();
    try {
      const mutationDoc = r"""
        mutation CreateUserFavorite($input: CreateUserFavoriteInput!) {
          createUserFavorite(input: $input) {
            id
            sessionId
            _version
          }
        }
      """;

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': recordId,
                      'userId': userId,
                      'sessionId': sessionId,
                      '_version': 1,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        favoriteIds.remove(sessionId);
        favoritedSessions.removeWhere((s) => s.id == sessionId);
        print('❌ FavoritesController._createRecord: ${response.errors}');
        return;
      }

      final version =
          _parseVersion(response.data ?? '', 'createUserFavorite') ?? 1;
      // Overwrite _records with the new record so future deletes use the
      // correct ID and version.
      _records[sessionId] = _FavRecord(
        id: recordId,
        version: version,
        isDeleted: false,
      );
      print(
        '✅ FavoritesController: created $sessionId id=$recordId v=$version',
      );
    } catch (e) {
      favoriteIds.remove(sessionId);
      favoritedSessions.removeWhere((s) => s.id == sessionId);
      print('❌ FavoritesController._createRecord: $e');
    }
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> _removeFavorite(String sessionId) async {
    var record = _records[sessionId];

    // Optimistic update.
    favoriteIds.remove(sessionId);
    favoritedSessions.removeWhere((s) => s.id == sessionId);

    if (record == null || record.isDeleted) {
      // Nothing active to delete — already gone.
      print(
        '⚠️ FavoritesController: no active record to delete for $sessionId',
      );
      return;
    }

    // Mark locally as deleted.
    _records[sessionId] = _FavRecord(
      id: record.id,
      version: record.version,
      isDeleted: true,
    );

    await _deleteRecord(sessionId, record);
  }

  Future<void> _deleteRecord(String sessionId, _FavRecord record) async {
    const mutationDoc = r"""
      mutation DeleteUserFavorite($input: DeleteUserFavoriteInput!) {
        deleteUserFavorite(input: $input) {
          id
          _version
        }
      }
    """;

    // ✅ FIX: Try the live version from AppSync first. If AppSync returns
    // null (record not yet synced — common when deleting immediately after
    // creating), fall back to the cached version we stored in _createRecord.
    // This handles the "favorite then immediately unfavorite" case.
    int version = record.version;
    final liveVersion = await _fetchLiveVersion(record.id);
    if (liveVersion != null) {
      version = liveVersion;
    } else {
      print(
        '⚠️ FavoritesController: AppSync returned null for ${record.id} '
        '(not synced yet) — using cached version $version',
      );
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {'id': record.id, '_version': version},
                  },
                ),
              )
              .response;

      if (response.errors.isEmpty) {
        final newVersion = _parseVersion(
          response.data ?? '',
          'deleteUserFavorite',
        );
        _records[sessionId] = _FavRecord(
          id: record.id,
          version: newVersion ?? version + 1,
          isDeleted: true,
        );
        print(
          '✅ FavoritesController: deleted $sessionId (attempt ${attempt + 1})',
        );
        return;
      }

      final isConflict = response.errors.any(
        (e) =>
            e.extensions?['errorType']?.toString().contains('Conflict') == true,
      );

      if (isConflict && attempt == 0) {
        // Version was wrong — fetch fresh and retry once.
        final fresh = await _fetchLiveVersion(record.id);
        if (fresh == null) {
          // Already deleted by the time we retried — that's fine.
          print('✅ FavoritesController: $sessionId already deleted on retry');
          return;
        }
        version = fresh;
        continue;
      }

      // Roll back on non-conflict error or second failure.
      print('❌ FavoritesController._deleteRecord: ${response.errors}');
      favoriteIds.add(sessionId);
      await _addSessionToFavoritedList(sessionId);
      _records[sessionId] = _FavRecord(
        id: record.id,
        version: version,
        isDeleted: false,
      );
      return;
    }
  }

  /// Returns the live _version from AppSync for an active (non-deleted) record.
  /// Returns null if the record doesn't exist yet on AppSync or is soft-deleted.
  Future<int?> _fetchLiveVersion(String recordId) async {
    try {
      const getDoc = r"""
        query GetUserFavorite($id: ID!) {
          getUserFavorite(id: $id) {
            id
            _version
            _deleted
          }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': recordId},
                ),
              )
              .response;
      if (response.errors.isEmpty && response.data != null) {
        final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getUserFavorite'] as Map<String, dynamic>?;
        if (obj == null || obj['_deleted'] == true) return null;
        final v = obj['_version'];
        if (v != null) return (v as num).toInt();
      }
    } catch (e) {
      print('⚠️ FavoritesController._fetchLiveVersion: $e');
    }
    return null;
  }

  // =========================================================================
  // PUBLIC HELPERS
  // =========================================================================

  bool isFavourite(String sessionId) => favoriteIds.contains(sessionId);
  bool isToggling(String sessionId) => _inProgress.contains(sessionId);

  Future<void> reloadForUser() async {
    _currentUserId = null;
    _tutoringWorker?.dispose();
    _homeWorker?.dispose();
    await _loadFavorites();
    _attachSessionWatchers();
  }

  void clearOnLogout() {
    _tutoringWorker?.dispose();
    _homeWorker?.dispose();
    _tutoringWorker = null;
    _homeWorker = null;
    _currentUserId = null;
    favoriteIds.clear();
    favoritedSessions.clear();
    _records.clear();
    _inProgress.clear();
    print('✅ FavoritesController: cleared on logout');
  }
}

class _FavRecord {
  final String id;
  final int version;
  final bool isDeleted;

  const _FavRecord({
    required this.id,
    required this.version,
    required this.isDeleted,
  });
}
