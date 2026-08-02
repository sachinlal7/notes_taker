import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  NotesCubit({
    Future<Note> Function({required String title, required String body})?
    createNote,
    Future<Note> Function({
      required String id,
      required String title,
      required String body,
    })?
    updateNote,
  }) : _createNote = createNote,
       _updateNote = updateNote,
       super(const NotesState(notes: []));

  final Future<Note> Function({required String title, required String body})?
  _createNote;
  final Future<Note> Function({
    required String id,
    required String title,
    required String body,
  })?
  _updateNote;

  Future<void> load(Future<List<Note>> Function() getAllNotes) async {
    try {
      final notes = await getAllNotes();
      if (!isClosed) emit(state.copyWith(notes: notes, isOffline: false));
    } on Object {
      if (!isClosed) emit(state.copyWith(isOffline: true));
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

    if (!state.isOffline && _createNote != null) {
      try {
        final note = await _createNote(title: cleanTitle, body: cleanBody);
        if (!isClosed) emit(state.copyWith(notes: [note, ...state.notes]));
        return;
      } on Object {
        if (!isClosed) emit(state.copyWith(isOffline: true));
      }
    }

    if (!isClosed) {
      final now = DateTime.now();
      emit(
        state.copyWith(
          notes: [
            Note(
              id: now.microsecondsSinceEpoch.toString(),
              title: cleanTitle,
              body: cleanBody,
              updatedAt: now,
              status: SyncStatus.pending,
            ),
            ...state.notes,
          ],
        ),
      );
    }
  }

  Future<void> update({
    required String id,
    required String title,
    required String body,
  }) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) return;

    if (!state.isOffline && _updateNote != null) {
      try {
        final note = await _updateNote(
          id: id,
          title: cleanTitle,
          body: cleanBody,
        );
        if (!isClosed) _replace(note);
        return;
      } on Object {
        if (!isClosed) emit(state.copyWith(isOffline: true));
      }
    }

    if (!isClosed) save(id: id, title: cleanTitle, body: cleanBody);
  }

  void save({String? id, required String title, required String body}) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) return;

    final now = DateTime.now();
    if (id == null) return;
    final current = byId(id);
    if (current == null) return;
    _replace(
      current.copyWith(
        title: cleanTitle,
        body: cleanBody,
        updatedAt: now,
        status: state.isOffline ? SyncStatus.pending : SyncStatus.synced,
        version: current.version + 1,
      ),
    );
  }

  void _replace(Note updated) {
    emit(
      state.copyWith(
        notes: [
          for (final note in state.notes)
            if (note.id == updated.id) updated else note,
        ],
      ),
    );
  }

  void delete(String id) {
    emit(
      state.copyWith(
        notes: state.notes.where((note) => note.id != id).toList(),
      ),
    );
  }

  void setOffline(bool value) => emit(state.copyWith(isOffline: value));

  void setDarkMode(bool value) => emit(state.copyWith(darkMode: value));

  void resolveConflict(String id, String body) {
    final note = byId(id);
    if (note == null) return;
    save(id: id, title: note.title, body: body);
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

    for (final step in const [
      (SyncPhase.uploading, .25),
      (SyncPhase.downloading, .55),
      (SyncPhase.resolving, .82),
    ]) {
      emit(state.copyWith(syncPhase: step.$1, syncProgress: step.$2));
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    emit(
      state.copyWith(
        notes: [
          for (final note in state.notes)
            if (note.status == SyncStatus.pending)
              note.copyWith(status: SyncStatus.synced)
            else
              note,
        ],
        syncPhase: SyncPhase.complete,
        syncProgress: 1,
      ),
    );
  }
}
