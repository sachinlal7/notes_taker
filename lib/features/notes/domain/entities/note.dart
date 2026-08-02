import 'package:equatable/equatable.dart';

enum SyncStatus { synced, pending, conflict }

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.status,
    this.version = 1,
    this.serverBody,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final SyncStatus status;
  final int version;
  final String? serverBody;

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    SyncStatus? status,
    int? version,
    String? serverBody,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      version: version ?? this.version,
      serverBody: serverBody ?? this.serverBody,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    updatedAt,
    status,
    version,
    serverBody,
  ];
}
