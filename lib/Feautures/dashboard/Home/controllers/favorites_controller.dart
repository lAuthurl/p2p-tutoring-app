// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import '../../../../models/ModelProvider.dart';
import '../../../Courses/controllers/tutoring_controller.dart';
import 'home_controller.dart';

/// Favorites are stored as a single UserFavorite row per user+session pair.
///
/// Add/Remove strategy:
///   • First favorite  → CREATE a new record (_version: 1)
///   • Re-favorite     → UPDATE the existing record (_deleted: false)
///   • Un-favorite     → DELETE (soft-delete via AppSync, _deleted: true)
///
/// favoritedSessions is kept in sync automatically:
///   1. On login — _loadFavorites() fetches IDs + hydrates sessions directly.
///   2. Auto-watch — workers on TutoringController.sessions and
///      HomeController.allSessions re-hydrate favoritedSessions the moment
///      either list populates, so the UI updates without any manual reload.
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
  final _inProgress = <String>{};
  String? _currentUserId;

  // Workers that watch other controllers' session lists.
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
  // AUTO-WATCH — re-hydrate favoritedSessions when any session list updates
  // =========================================================================

  void _attachSessionWatchers() {
    // Watch TutoringController.sessions (DataStore observeQuery).
    // Fires every time DataStore pushes a new snapshot — including the first
    // one after login when sessions finally arrive from AppSync sync.
    _tutoringWorker?.dispose();
    _tutoringWorker = ever<List<TutoringSession>>(
      TutoringController.instance.sessions,
      (_) => _rehydrateFromExistingSources(),
    );

    // Watch HomeController.allSessions (GraphQL load).
    // Fires when HomeController finishes its _loadAllSessionsFromGraphQL().
    _homeWorker?.dispose();
    if (Get.isRegistered<HomeController>()) {
      _homeWorker = ever<List<TutoringSession>>(
        HomeController.instance.allSessions,
        (_) => _rehydrateFromExistingSources(),
      );
    }
  }

  /// Re-hydrate favoritedSessions using already-loaded sessions from other
  /// controllers. Does NOT make any network calls — purely assembles from
  /// what's already in memory. Called automatically by watchers.
  void _rehydrateFromExistingSources() {
    if (favoriteIds.isEmpty) return;

    // Build a lookup map from every session source we have.
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

    // For each favorited id that we now have a session for, update the list.
    bool changed = false;
    final current = {for (final s in favoritedSessions) s.id: s};

    for (final id in favoriteIds) {
      final inPool = pool[id];
      if (inPool == null) continue;

      final existing = current[id];
      // Replace if missing or if the new version has a tutor name (more data).
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
      print(
        '🔄 FavoritesController: re-hydrated ${favoritedSessions.length} sessions from local pool',
      );
    }
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

    print(
      '⚠️ FavoritesController: could not resolve userId after $retries attempts',
    );
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

      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'userId': userId, 'limit': 1000},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty || response.data == null) {
        print('⚠️ FavoritesController: load failed — ${response.errors}');
        return;
      }

      _parseResponse(response.data!);

      // Step 1: Try to hydrate from already-loaded controllers (instant).
      _rehydrateFromExistingSources();

      // Step 2: For any ids still missing, fetch directly from DataStore/AppSync.
      await _hydrateMissingSessions();

      print(
        '✅ FavoritesController: loaded ${favoriteIds.length} active favorites, '
        '${favoritedSessions.length} sessions hydrated for user $userId',
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
      final items =
          (decoded['listUserFavoritesByUser']
                  as Map<String, dynamic>?)?['items']
              as List<dynamic>? ??
          [];

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

  /// Fetch sessions for any favoriteId not yet in favoritedSessions.
  Future<void> _hydrateMissingSessions() async {
    final currentIds = favoritedSessions.map((s) => s.id).toSet();
    final missing =
        favoriteIds.where((id) => !currentIds.contains(id)).toList();
    if (missing.isEmpty) return;

    for (final sessionId in missing) {
      try {
        // DataStore first (fast local cache).
        final local = await Amplify.DataStore.query(
          TutoringSession.classType,
          where: TutoringSession.ID.eq(sessionId),
        );

        if (local.isNotEmpty) {
          final hydrated = await _resolveSessionTutor(local.first);
          favoritedSessions.add(hydrated);
          continue;
        }

        // Direct AppSync fallback.
        final remote = await _fetchSessionFromAppSync(sessionId);
        if (remote != null) favoritedSessions.add(remote);
      } catch (e) {
        print(
          '⚠️ FavoritesController: could not hydrate session $sessionId: $e',
        );
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
      final data = decoded['getTutoringSession'] as Map<String, dynamic>?;
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
    if (_inProgress.contains(sessionId)) {
      print(
        '⚠️ FavoritesController: toggle in progress for $sessionId, ignoring',
      );
      return;
    }

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

  Future<void> _addFavorite(String sessionId, String userId) async {
    favoriteIds.add(sessionId);
    await _addSessionToFavoritedList(sessionId);

    final existing = _records[sessionId];
    if (existing != null) {
      print(
        '🔄 FavoritesController: reviving existing record for $sessionId '
        '(id=${existing.id}, wasDeleted=${existing.isDeleted})',
      );
      await _reviveRecord(sessionId, existing, userId);
    } else {
      await _createRecord(sessionId, userId);
    }
  }

  Future<void> _addSessionToFavoritedList(String sessionId) async {
    if (favoritedSessions.any((s) => s.id == sessionId)) return;
    try {
      final local = await Amplify.DataStore.query(
        TutoringSession.classType,
        where: TutoringSession.ID.eq(sessionId),
      );
      if (local.isNotEmpty) {
        final hydrated = await _resolveSessionTutor(local.first);
        favoritedSessions.add(hydrated);
        return;
      }
      final remote = await _fetchSessionFromAppSync(sessionId);
      if (remote != null) favoritedSessions.add(remote);
    } catch (e) {
      print('⚠️ FavoritesController._addSessionToFavoritedList: $e');
    }
  }

  Future<void> _reviveRecord(
    String sessionId,
    _FavRecord record,
    String userId,
  ) async {
    try {
      int version = record.version;
      final liveVersion = await _fetchLiveVersion(record.id);
      if (liveVersion != null) version = liveVersion;

      const mutationDoc = r"""
        mutation UpdateUserFavorite($input: UpdateUserFavoriteInput!) {
          updateUserFavorite(input: $input) {
            id
            sessionId
            _version
            _deleted
          }
        }
      """;

      final request = GraphQLRequest<String>(
        document: mutationDoc,
        variables: {
          'input': {
            'id': record.id,
            'userId': userId,
            'sessionId': sessionId,
            '_version': version,
          },
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        favoriteIds.remove(sessionId);
        favoritedSessions.removeWhere((s) => s.id == sessionId);
        print('❌ FavoritesController._reviveRecord: ${response.errors}');
        return;
      }

      final newVersion = _parseVersion(
        response.data ?? '',
        'updateUserFavorite',
      );
      _records[sessionId] = _FavRecord(
        id: record.id,
        version: newVersion ?? version + 1,
        isDeleted: false,
      );
      print(
        '✅ FavoritesController: revived $sessionId (v=${newVersion ?? version + 1})',
      );
    } catch (e) {
      favoriteIds.remove(sessionId);
      favoritedSessions.removeWhere((s) => s.id == sessionId);
      print('❌ FavoritesController._reviveRecord: $e');
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

      final request = GraphQLRequest<String>(
        document: mutationDoc,
        variables: {
          'input': {
            'id': recordId,
            'userId': userId,
            'sessionId': sessionId,
            '_version': 1,
          },
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        favoriteIds.remove(sessionId);
        favoritedSessions.removeWhere((s) => s.id == sessionId);
        print('❌ FavoritesController._createRecord: ${response.errors}');
        return;
      }

      final version = _parseVersion(response.data ?? '', 'createUserFavorite');
      _records[sessionId] = _FavRecord(
        id: recordId,
        version: version ?? 1,
        isDeleted: false,
      );
      print('✅ FavoritesController: created $sessionId (v=${version ?? 1})');
    } catch (e) {
      favoriteIds.remove(sessionId);
      favoritedSessions.removeWhere((s) => s.id == sessionId);
      print('❌ FavoritesController._createRecord: $e');
    }
  }

  Future<void> _removeFavorite(String sessionId) async {
    var record = _records[sessionId];

    favoriteIds.remove(sessionId);
    favoritedSessions.removeWhere((s) => s.id == sessionId);

    if (record == null) {
      print(
        '⚠️ FavoritesController: no record cached for $sessionId, reloading...',
      );
      await _loadFavorites();
      record = _records[sessionId];
      if (record == null) return;
      favoriteIds.remove(sessionId);
      favoritedSessions.removeWhere((s) => s.id == sessionId);
    }

    _records[sessionId] = _FavRecord(
      id: record.id,
      version: record.version,
      isDeleted: true,
    );

    await _deleteRecord(sessionId, record);
  }

  Future<void> _deleteRecord(String sessionId, _FavRecord record) async {
    try {
      int version = record.version;
      final liveVersion = await _fetchLiveVersion(record.id);
      if (liveVersion != null) version = liveVersion;

      const mutationDoc = r"""
        mutation DeleteUserFavorite($input: DeleteUserFavoriteInput!) {
          deleteUserFavorite(input: $input) {
            id
            _version
          }
        }
      """;

      final request = GraphQLRequest<String>(
        document: mutationDoc,
        variables: {
          'input': {'id': record.id, '_version': version},
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        favoriteIds.add(sessionId);
        await _addSessionToFavoritedList(sessionId);
        _records[sessionId] = _FavRecord(
          id: record.id,
          version: version,
          isDeleted: false,
        );
        print('❌ FavoritesController._deleteRecord: ${response.errors}');
      } else {
        final newVersion = _parseVersion(
          response.data ?? '',
          'deleteUserFavorite',
        );
        _records[sessionId] = _FavRecord(
          id: record.id,
          version: newVersion ?? version + 1,
          isDeleted: true,
        );
        print('✅ FavoritesController: un-favorited $sessionId');
      }
    } catch (e) {
      favoriteIds.add(sessionId);
      await _addSessionToFavoritedList(sessionId);
      _records[sessionId] = _FavRecord(
        id: record.id,
        version: record.version,
        isDeleted: false,
      );
      print('❌ FavoritesController._deleteRecord: $e');
    }
  }

  Future<int?> _fetchLiveVersion(String recordId) async {
    try {
      const getDoc = r"""
        query GetUserFavorite($id: ID!) {
          getUserFavorite(id: $id) {
            id
            _version
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
        return _parseVersion(response.data!, 'getUserFavorite');
      }
    } catch (e) {
      print('⚠️ FavoritesController._fetchLiveVersion: $e');
    }
    return null;
  }

  int? _parseVersion(String jsonStr, String operationKey) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return (decoded[operationKey]?['_version'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // PUBLIC HELPERS
  // =========================================================================

  bool isFavourite(String sessionId) => favoriteIds.contains(sessionId);

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

// ── Internal record model ─────────────────────────────────────────────────────
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
