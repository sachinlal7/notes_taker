import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/note.dart';

class NotesRepository {
  const NotesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Note>> getAll() async {
    final response = await _apiClient.get<List<dynamic>>('/notes');
    return response.data.map(_parseNote).toList(growable: false);
  }

  Future<Note> create({required String title, required String body}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/notes',
      body: {'title': title, 'body': body, 'status': 'pending'},
    );
    return _parseNote(response.data);
  }

  Future<Note> update({
    required String id,
    required String title,
    required String body,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/notes/$id',
      body: {'title': title, 'body': body, 'status': 'synced'},
    );
    return _parseNote(response.data);
  }

  Note _parseNote(Object? value) {
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
      'synced' => SyncStatus.synced,
      'pending' => SyncStatus.pending,
      'conflict' => SyncStatus.conflict,
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
    );
  }
}
