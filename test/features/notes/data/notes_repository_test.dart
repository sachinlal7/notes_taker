import 'package:flutter_test/flutter_test.dart';
import 'package:notes_taker/core/network/api_client.dart';
import 'package:notes_taker/core/network/api_response.dart';
import 'package:notes_taker/features/notes/data/notes_repository.dart';
import 'package:notes_taker/features/notes/domain/entities/note.dart';

void main() {
  test('gets and parses all notes', () async {
    final notes = await NotesRepository(_FakeApiClient()).getAll();

    expect(notes, hasLength(1));
    expect(notes.single.title, 'Shopping list new');
    expect(notes.single.status, SyncStatus.pending);
    expect(notes.single.version, 1);
  });

  test('creates a pending note', () async {
    final note = await NotesRepository(
      _FakeApiClient(),
    ).create(title: 'Shopping list', body: 'Milk, eggs, bread');

    expect(note.id, '2');
    expect(note.status, SyncStatus.pending);
  });

  test('updates a note as synced', () async {
    final note = await NotesRepository(_FakeApiClient()).update(
      id: '1',
      title: 'Project ideas (updated)',
      body: 'Create an offline notes application with sync support',
    );

    expect(note.version, 2);
    expect(note.status, SyncStatus.synced);
  });
}

class _FakeApiClient implements ApiClient {
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic cancelToken,
  }) async {
    expect(path, '/notes');
    return ApiResponse<T>(
      data:
          [
                {
                  'createdAt': '2026-08-01T07:30:01.589Z',
                  'name': 'Pauline Schultz',
                  'avatar': 'https://avatars.githubusercontent.com/u/88702361',
                  'id': '1',
                  'title': 'Shopping list new',
                  'body': 'Milk, eggs, bread',
                  'status': 'pending',
                },
              ]
              as T,
    );
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    dynamic cancelToken,
  }) async {
    expect(path, '/notes');
    expect(body, {
      'title': 'Shopping list',
      'body': 'Milk, eggs, bread',
      'status': 'pending',
    });
    return ApiResponse<T>(
      data:
          {
                'id': '2',
                ...body!,
                'version': 1,
                'updatedAt': '2026-08-02T10:05:00Z',
              }
              as T,
    );
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    dynamic cancelToken,
  }) async {
    expect(path, '/notes/1');
    expect(body, {
      'title': 'Project ideas (updated)',
      'body': 'Create an offline notes application with sync support',
      'status': 'synced',
    });
    return ApiResponse<T>(
      data:
          {
                'id': '1',
                ...body!,
                'version': 2,
                'updatedAt': '2026-08-02T10:10:00Z',
              }
              as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
