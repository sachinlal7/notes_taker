import 'package:isar_community/isar.dart';

import '../domain/entities/note.dart';

part 'note_record.g.dart';

enum PendingOperation { none, create, update, delete }

@collection
class NoteRecord {
  Id id = Isar.autoIncrement;

  late String localId;

  String? remoteId;
  late String title;
  late String body;
  late DateTime updatedAt;

  @enumerated
  SyncStatus status = SyncStatus.synced;

  @enumerated
  PendingOperation pendingOperation = PendingOperation.none;

  int version = 1;
  String? serverBody;
}
