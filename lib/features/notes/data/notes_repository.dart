import 'dart:async';
import 'dart:math';

import 'package:isar_community/isar.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_info.dart';
import '../domain/entities/note.dart';
import 'note_record.dart';

class NotesRepository {
  NotesRepository(
    this._apiClient,
    this._isar,
    this._networkInfo, {
    Future<void> Function()? scheduleBackgroundSync,
  }) : _scheduleBackgroundSync = scheduleBackgroundSync;

  static const _notesPath = '/notes';
  static final _random = Random.secure();

  final ApiClient _apiClient;
  final Isar _isar;
  final NetworkInfo _networkInfo;
  final Future<void> Function()? _scheduleBackgroundSync;
  final _connectionController = StreamController<bool>.broadcast();

  StreamSubscription<bool>? _connectionSubscription;
  Future<bool>? _activeSync;
  bool _online = false;

  IsarCollection<NoteRecord> get _records => _isar.noteRecords;
  Stream<bool> get connectionChanges => _connectionController.stream;
  bool get isOnline => _online;

  Stream<List<Note>> watchNotes() {
    return _records.watchLazy(fireImmediately: true).asyncMap((_) async {
      final records = await _records.where().findAll();
      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return records
          .where((record) => record.pendingOperation != PendingOperation.delete)
          .map(_toNote)
          .toList(growable: false);
    });
  }

  Future<void> start() async {
    if (_connectionSubscription != null) return;

    _setOnline(await _networkInfo.isConnected);
    _connectionSubscription = _networkInfo.onStatusChange.listen((online) {
      _setOnline(online);
      if (online) unawaited(sync());
    });
    if (_online) unawaited(sync());
  }

  Future<void> stop() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }

  Future<void> create({required String title, required String body}) async {
    final now = DateTime.now();
    final record = NoteRecord()
      ..localId = _newLocalId(now)
      ..title = title.trim()
      ..body = body.trim()
      ..updatedAt = now
      ..status = SyncStatus.pending
      ..pendingOperation = PendingOperation.create;

    await _isar.writeTxn(() => _records.put(record));
    _scheduleSync();
  }

  Future<void> update({
    required String id,
    required String title,
    required String body,
  }) async {
    final record = await _findByLocalId(id);
    if (record == null) return;

    record
      ..title = title.trim()
      ..body = body.trim()
      ..updatedAt = DateTime.now()
      ..version = record.version + 1
      ..status = SyncStatus.pending
      ..pendingOperation = record.pendingOperation == PendingOperation.create
          ? PendingOperation.create
          : PendingOperation.update;

    await _isar.writeTxn(() => _records.put(record));
    _scheduleSync();
  }

  Future<void> delete(String id) async {
    final record = await _findByLocalId(id);
    if (record == null) return;

    record
      ..status = SyncStatus.pending
      ..pendingOperation = PendingOperation.delete;
    await _isar.writeTxn(() => _records.put(record));
    _scheduleSync();
  }

  Future<bool> sync() {
    final activeSync = _activeSync;
    if (activeSync != null) return activeSync;

    late final Future<bool> syncFuture;
    syncFuture = _performSync().whenComplete(() {
      if (identical(_activeSync, syncFuture)) _activeSync = null;
    });
    _activeSync = syncFuture;
    return syncFuture;
  }

  Future<bool> _performSync() async {
    final online = await _networkInfo.isConnected;
    _setOnline(online);
    if (!online) return false;

    try {
      await _uploadPending();
      final remoteNotes = await _getRemoteNotes();
      await _mergeRemote(remoteNotes);
      return true;
    } on Object {
      _setOnline(await _networkInfo.isConnected);
      return false;
    }
  }

  Future<void> _uploadPending() async {
    while (true) {
      final records = await _records.where().findAll();
      final pending = records
          .where((record) => record.pendingOperation != PendingOperation.none)
          .toList(growable: false);
      if (pending.isEmpty) return;

      for (final record in pending) {
        switch (record.pendingOperation) {
          case PendingOperation.none:
            break;
          case PendingOperation.create:
            await _uploadCreate(record);
          case PendingOperation.update:
            await _uploadUpdate(record);
          case PendingOperation.delete:
            await _uploadDelete(record);
        }
      }
    }
  }

  Future<void> _uploadCreate(NoteRecord sent) async {
    // ponytail: MockAPI has no idempotency key; add a unique clientId on the
    // server if duplicate-free recovery after a crash during POST is required.
    final remote = await _createRemote(sent);
    await _isar.writeTxn(() async {
      final latest = await _records.get(sent.id);
      if (latest == null) return;

      latest.remoteId = remote.id;
      if (_unchanged(latest, sent, PendingOperation.create)) {
        _applyRemote(latest, remote);
      } else if (latest.pendingOperation != PendingOperation.delete) {
        latest
          ..status = SyncStatus.pending
          ..pendingOperation = PendingOperation.update;
      }
      await _records.put(latest);
    });
  }

  Future<void> _uploadUpdate(NoteRecord sent) async {
    if (sent.remoteId == null) {
      await _uploadCreate(sent);
      return;
    }

    final remote = await _updateRemote(sent);
    await _isar.writeTxn(() async {
      final latest = await _records.get(sent.id);
      if (latest == null) return;

      if (_unchanged(latest, sent, PendingOperation.update)) {
        _applyRemote(latest, remote);
      }
      await _records.put(latest);
    });
  }

  Future<void> _uploadDelete(NoteRecord sent) async {
    if (sent.remoteId != null) {
      await _apiClient.delete<Map<String, dynamic>>(
        '$_notesPath/${sent.remoteId}',
      );
    }
    await _isar.writeTxn(() async {
      final latest = await _records.get(sent.id);
      if (latest?.pendingOperation == PendingOperation.delete) {
        await _records.delete(sent.id);
      }
    });
  }

  Future<List<Note>> _getRemoteNotes() async {
    final response = await _apiClient.get<List<dynamic>>(_notesPath);
    return response.data.map(_parseRemoteNote).toList(growable: false);
  }

  Future<Note> _createRemote(NoteRecord record) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _notesPath,
      body: _remoteBody(record),
    );
    return _parseRemoteNote(response.data);
  }

  Future<Note> _updateRemote(NoteRecord record) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '$_notesPath/${record.remoteId}',
      body: _remoteBody(record),
    );
    return _parseRemoteNote(response.data);
  }

  Future<void> _mergeRemote(List<Note> remoteNotes) async {
    await _isar.writeTxn(() async {
      final localRecords = await _records.where().findAll();
      final byRemoteId = <String, NoteRecord>{
        for (final record in localRecords)
          if (record.remoteId != null) record.remoteId!: record,
      };
      final remoteIds = remoteNotes.map((note) => note.id).toSet();
      final upserts = <NoteRecord>[];

      for (final remote in remoteNotes) {
        final local = byRemoteId[remote.id];
        if (local == null) {
          final record = NoteRecord()
            ..localId = 'remote:${remote.id}'
            ..remoteId = remote.id;
          _applyRemote(record, remote);
          upserts.add(record);
        } else if (local.pendingOperation == PendingOperation.none) {
          _applyRemote(local, remote);
          upserts.add(local);
        }
      }

      final removedIds = localRecords
          .where(
            (record) =>
                record.remoteId != null &&
                record.pendingOperation == PendingOperation.none &&
                !remoteIds.contains(record.remoteId),
          )
          .map((record) => record.id)
          .toList(growable: false);

      if (upserts.isNotEmpty) await _records.putAll(upserts);
      if (removedIds.isNotEmpty) await _records.deleteAll(removedIds);
    });
  }

  Future<NoteRecord?> _findByLocalId(String localId) async {
    // ponytail: linear scans are fine for a notes app; add an index query when
    // profiling shows this collection is large enough to matter.
    final records = await _records.where().findAll();
    for (final record in records) {
      if (record.localId == localId) return record;
    }
    return null;
  }

  Map<String, dynamic> _remoteBody(NoteRecord record) => {
    'title': record.title,
    'body': record.body,
    'status': 'synced',
    'version': record.version,
    'updatedAt': record.updatedAt.toUtc().toIso8601String(),
  };

  Note _parseRemoteNote(Object? value) {
    if (value is! Map) throw const ServerException('Invalid note response.');

    final json = Map<String, dynamic>.from(value);
    final id = json['id']?.toString();
    final title = json['title'];
    final body = json['body'];
    final updatedAt = DateTime.tryParse(
      (json['updatedAt'] ?? json['createdAt'])?.toString() ?? '',
    );
    final version = json['version'] is num
        ? (json['version'] as num).toInt()
        : 1;
    final status = switch (json['status']) {
      'conflict' => SyncStatus.conflict,
      'synced' || 'pending' => SyncStatus.synced,
      _ => null,
    };

    if (id == null ||
        title is! String ||
        body is! String ||
        updatedAt == null ||
        status == null) {
      throw const ServerException('Invalid note response.');
    }

    return Note(
      id: id,
      title: title,
      body: body,
      updatedAt: updatedAt,
      status: status,
      version: version,
      serverBody: json['serverBody'] as String?,
    );
  }

  Note _toNote(NoteRecord record) => Note(
    id: record.localId,
    title: record.title,
    body: record.body,
    updatedAt: record.updatedAt,
    status: record.status,
    version: record.version,
    serverBody: record.serverBody,
  );

  void _applyRemote(NoteRecord record, Note remote) {
    record
      ..remoteId = remote.id
      ..title = remote.title
      ..body = remote.body
      ..updatedAt = remote.updatedAt
      ..status = remote.status
      ..version = remote.version
      ..serverBody = remote.serverBody
      ..pendingOperation = PendingOperation.none;
  }

  bool _unchanged(
    NoteRecord latest,
    NoteRecord sent,
    PendingOperation operation,
  ) {
    return latest.pendingOperation == operation &&
        latest.updatedAt.isAtSameMomentAs(sent.updatedAt);
  }

  String _newLocalId(DateTime now) {
    return 'local:${now.microsecondsSinceEpoch.toRadixString(36)}:'
        '${_random.nextInt(1 << 32).toRadixString(36)}';
  }

  void _scheduleSync() {
    if (_online) unawaited(sync());
    if (_scheduleBackgroundSync case final schedule?) {
      unawaited(_scheduleSafely(schedule));
    }
  }

  Future<void> _scheduleSafely(Future<void> Function() schedule) async {
    try {
      await schedule();
    } on Object {
      // Foreground sync and the persistent Isar queue remain the fallback.
    }
  }

  void _setOnline(bool online) {
    _online = online;
    if (!_connectionController.isClosed) _connectionController.add(online);
  }
}
