import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notes_repository.dart';
import '../../domain/entities/note.dart';

enum SyncPhase { idle, uploading, downloading, resolving, complete, failed }

class NotesState extends Equatable {
  const NotesState({
    required this.notes,
    this.isOffline = false,
    this.darkMode = false,
    this.syncPhase = SyncPhase.idle,
    this.syncProgress = 0,
  });

  final List<Note> notes;
  final bool isOffline;
  final bool darkMode;
  final SyncPhase syncPhase;
  final double syncProgress;

  int get pendingCount =>
      notes.where((note) => note.status == SyncStatus.pending).length;
  int get conflictCount =>
      notes.where((note) => note.status == SyncStatus.conflict).length;

  NotesState copyWith({
    List<Note>? notes,
    bool? isOffline,
    bool? darkMode,
    SyncPhase? syncPhase,
    double? syncProgress,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isOffline: isOffline ?? this.isOffline,
      darkMode: darkMode ?? this.darkMode,
      syncPhase: syncPhase ?? this.syncPhase,
      syncProgress: syncProgress ?? this.syncProgress,
    );
  }

  @override
  List<Object> get props => [
    notes,
    isOffline,
    darkMode,
    syncPhase,
    syncProgress,
  ];
}

class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository) : super(const NotesState(notes: []));

  final NotesRepository _repository;
  StreamSubscription<List<Note>>? _notesSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  Future<void> start() async {
    _notesSubscription = _repository.watchNotes().listen(
      (notes) {
        if (!isClosed) emit(state.copyWith(notes: notes));
      },
      onError: (_) {
        if (!isClosed) emit(state.copyWith(syncPhase: SyncPhase.failed));
      },
    );
    _connectionSubscription = _repository.connectionChanges.listen((online) {
      if (!isClosed) emit(state.copyWith(isOffline: !online));
    });

    await _repository.start();
    if (!isClosed) {
      emit(state.copyWith(isOffline: !_repository.isOnline));
    }
  }

  Note? byId(String id) {
    for (final note in state.notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<void> create({required String title, required String body}) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) return;

    await _repository.create(title: cleanTitle, body: cleanBody);
  }

  Future<void> update({
    required String id,
    required String title,
    required String body,
  }) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) return;

    await _repository.update(id: id, title: cleanTitle, body: cleanBody);
  }

  Future<void> delete(String id) => _repository.delete(id);

  void setDarkMode(bool value) => emit(state.copyWith(darkMode: value));

  Future<void> resolveConflict(String id, String body) async {
    final note = byId(id);
    if (note == null) return;
    await update(id: id, title: note.title, body: body);
  }

  Future<void> sync() async {
    final isSyncing = switch (state.syncPhase) {
      SyncPhase.uploading ||
      SyncPhase.downloading ||
      SyncPhase.resolving => true,
      _ => false,
    };
    if (isSyncing) return;
    if (state.isOffline) {
      emit(state.copyWith(syncPhase: SyncPhase.failed, syncProgress: 0));
      return;
    }

    emit(state.copyWith(syncPhase: SyncPhase.uploading, syncProgress: .25));
    final success = await _repository.sync();
    if (isClosed) return;

    emit(
      state.copyWith(
        syncPhase: success ? SyncPhase.complete : SyncPhase.failed,
        syncProgress: success ? 1 : 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _notesSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _repository.stop();
    return super.close();
  }
}
