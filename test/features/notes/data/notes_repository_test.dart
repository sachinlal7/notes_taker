import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:notes_taker/core/network/api_client.dart';
import 'package:notes_taker/core/network/api_response.dart';
import 'package:notes_taker/core/network/network_info.dart';
import 'package:notes_taker/features/notes/data/note_record.dart';
import 'package:notes_taker/features/notes/data/notes_repository.dart';
import 'package:notes_taker/features/notes/domain/entities/note.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test(
    'persists multiple offline notes and uploads them after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'notes_isar_test_',
      );
      final api = _FakeApiClient();
      final network = _FakeNetworkInfo(false);
      var scheduledSyncs = 0;
      var isar = await Isar.open(
        [NoteRecordSchema],
        directory: directory.path,
        name: 'offline_sync_test',
      );
      var repository = NotesRepository(
        api,
        isar,
        network,
        scheduleBackgroundSync: () async => scheduledSyncs++,
      );

      await repository.start();
      await repository.create(title: 'First', body: 'Offline one');
      await repository.create(title: 'Second', body: 'Offline two');

      final offlineNotes = await repository.watchNotes().first;
      expect(offlineNotes, hasLength(2));
      expect(
        offlineNotes.every((note) => note.status == SyncStatus.pending),
        isTrue,
      );
      expect(api.notes, isEmpty);
      expect(scheduledSyncs, 2);

      await repository.stop();
      await isar.close();

      isar = await Isar.open(
        [NoteRecordSchema],
        directory: directory.path,
        name: 'offline_sync_test',
      );
      network.setOnline(true);
      repository = NotesRepository(api, isar, network);

      final notesBeforeSync = await repository.watchNotes().first;
      expect(notesBeforeSync, hasLength(2));

      await repository.start();
      expect(await repository.sync(), isTrue);
      expect(api.notes, hasLength(2));

      final syncedNotes = await repository.watchNotes().first;
      expect(
        syncedNotes.every((note) => note.status == SyncStatus.synced),
        isTrue,
      );

      final records = await isar.noteRecords.where().findAll();
      expect(
        records.every(
          (record) =>
              record.remoteId != null &&
              record.pendingOperation == PendingOperation.none,
        ),
        isTrue,
      );

      await repository.stop();
      await isar.close(deleteFromDisk: true);
      await directory.delete(recursive: true);
    },
  );

  test('does not upload an offline note deleted before sync', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notes_isar_delete_test_',
    );
    final api = _FakeApiClient();
    final network = _FakeNetworkInfo(false);
    final isar = await Isar.open(
      [NoteRecordSchema],
      directory: directory.path,
      name: 'offline_delete_test',
    );
    final repository = NotesRepository(api, isar, network);

    await repository.start();
    await repository.create(title: 'Temporary', body: 'Delete me');
    final note = (await repository.watchNotes().first).single;
    await repository.delete(note.id);

    network.setOnline(true);
    expect(await repository.sync(), isTrue);
    expect(api.notes, isEmpty);
    expect(await repository.watchNotes().first, isEmpty);

    await repository.stop();
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });
}

class _FakeNetworkInfo implements NetworkInfo {
  _FakeNetworkInfo(this.online);

  bool online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => online;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  void setOnline(bool value) {
    online = value;
    _controller.add(value);
  }
}

class _FakeApiClient implements ApiClient {
  final notes = <Map<String, dynamic>>[];
  var _nextId = 1;

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic cancelToken,
  }) async {
    expect(path, '/notes');
    return ApiResponse(data: List<Map<String, dynamic>>.from(notes) as T);
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    dynamic cancelToken,
  }) async {
    expect(path, '/notes');
    final note = <String, dynamic>{
      'id': (_nextId++).toString(),
      ...body!,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    notes.add(note);
    return ApiResponse(data: note as T);
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    dynamic cancelToken,
  }) async {
    final id = path.split('/').last;
    final index = notes.indexWhere((note) => note['id'] == id);
    notes[index] = {...notes[index], ...body!};
    return ApiResponse(data: notes[index] as T);
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    dynamic cancelToken,
  }) async {
    final id = path.split('/').last;
    final note = notes.firstWhere((note) => note['id'] == id);
    notes.remove(note);
    return ApiResponse(data: note as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
