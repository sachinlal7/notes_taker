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
  NotesCubit()
    : super(
        NotesState(
          isOffline: true,
          notes: [
            Note(
              id: 'meeting',
              title: 'Project Feedback Loop',
              body:
                  'The client requested a complete overhaul of the navigation structure. We need to resolve the local versus server version mismatch immediately.',
              serverBody:
                  'The client requested updates to navigation. Keep the existing structure and improve the sync controls.',
              updatedAt: DateTime.now().subtract(const Duration(days: 1)),
              status: SyncStatus.conflict,
              version: 7,
            ),
            Note(
              id: 'launch',
              title: 'Grocery List & Meal Prep',
              body:
                  'Almond milk, kale, salmon, quinoa. Check the pantry for balsamic vinegar before heading out to the market.',
              updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
              status: SyncStatus.pending,
              version: 5,
            ),
            Note(
              id: 'welcome',
              title: 'Architecture Review Notes',
              body:
                  'Database schema for the offline-first sync engine looks solid. We decided to use a vector clock approach for conflict resolution.',
              updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
              status: SyncStatus.synced,
              version: 3,
            ),
            Note(
              id: 'dream',
              title: 'Dream Journal: Ocean Sky',
              body:
                  'I was walking on water, but the sky was also water. Fish were swimming past my ears and everything was a deep violet color.',
              updatedAt: DateTime.now().subtract(const Duration(days: 2)),
              status: SyncStatus.synced,
            ),
          ],
        ),
      );

  Note? byId(String id) {
    for (final note in state.notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  void save({String? id, required String title, required String body}) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanBody.isEmpty) return;

    final now = DateTime.now();
    if (id == null) {
      final note = Note(
        id: now.microsecondsSinceEpoch.toString(),
        title: cleanTitle,
        body: cleanBody,
        updatedAt: now,
        status: state.isOffline ? SyncStatus.pending : SyncStatus.synced,
      );
      emit(state.copyWith(notes: [note, ...state.notes]));
      return;
    }

    emit(
      state.copyWith(
        notes: [
          for (final note in state.notes)
            if (note.id == id)
              note.copyWith(
                title: cleanTitle,
                body: cleanBody,
                updatedAt: now,
                status: state.isOffline
                    ? SyncStatus.pending
                    : SyncStatus.synced,
                version: note.version + 1,
              )
            else
              note,
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
