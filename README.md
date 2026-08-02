# Notes Taker

A Flutter notes application using an offline-first architecture. Isar is the
only source of truth for notes; the REST API is a synchronization target.

## Offline-first behavior

1. The app opens Isar before rendering the notes feature.
2. The UI subscribes to the Isar collection and displays local data immediately.
3. Create, update, and delete operations commit to Isar first.
4. Each local mutation stores a persistent pending operation and schedules sync.
5. When connectivity is available, the repository uploads every pending record.
6. It then downloads the server collection and merges it into Isar.
7. Isar emits the change and the UI refreshes automatically.

The UI never renders API responses directly and does not keep a competing
in-memory notes list.

## Architecture

```text
UI -> NotesCubit -> NotesRepository -> Isar
                         |
                         +-> REST API
                         |
                         +-> Workmanager wake-up

Isar watch stream -> NotesRepository -> NotesCubit -> UI
```

Responsibilities:

- `NoteRecord`: persisted note, remote ID, version, status, and pending operation.
- `NotesRepository`: local-first CRUD, queue processing, concurrency guard, remote
  parsing, merge, and connectivity-triggered sync.
- `NotesCubit`: presentation state and subscription lifecycle only.
- `BackgroundSyncScheduler`: asks the operating system to wake the repository;
  it does not store or mutate notes itself.
- `Isar`: sole notes database and durable sync queue.

Shared Preferences remains only for non-note application configuration. Notes
are not stored in Shared Preferences, SQLite, or an in-memory cache.

## Persisted sync states

| Pending operation | Meaning | Next successful sync |
| --- | --- | --- |
| `none` | Local record matches the server | No upload |
| `create` | Created locally without a remote ID | `POST /notes` |
| `update` | Local version is newer | `PATCH /notes/:id` |
| `delete` | Hidden local tombstone | `DELETE /notes/:id`, then remove locally |

Multiple offline notes remain queued across app restarts. A sync uses one guarded
worker, uploads the entire queue, pulls remote notes, and writes the result to
Isar in transactions. Edits or deletes made while a request is in flight remain
pending and are processed on the next queue pass.

## Background synchronization

Foreground behavior:

- App launch: show Isar immediately, then synchronize in the background.
- Network reconnect: synchronize automatically.
- Local mutation while online: save locally, then synchronize.
- Manual sync: delegates to the same repository method.

Operating-system behavior:

- Android: every local mutation schedules one unique, network-constrained task.
  A network-constrained periodic reconciliation also runs approximately hourly.
- iOS: Background Fetch is enabled. iOS decides when the app receives execution
  time, so execution is eventual rather than immediate. The deployment target
  is iOS 15 because that is the minimum required by the current Firebase packages.
- Both platforms retry safely because the durable queue remains in Isar when a
  task fails or the process stops.

The operating system controls exact background timing. Force-stopping an Android
app disables its scheduled work until the user opens it again; iOS may throttle
Background Fetch based on usage and battery conditions.

## REST API contract

Base URL is loaded from `.env.staging` or `.env.production`.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/notes` | Pull all remote notes |
| `POST` | `/notes` | Upload an offline-created note |
| `PATCH` | `/notes/:id` | Upload a local edit |
| `DELETE` | `/notes/:id` | Upload a local deletion |

Expected note fields:

```json
{
  "id": "1",
  "title": "Shopping list",
  "body": "Milk, eggs, bread",
  "status": "synced",
  "version": 1,
  "updatedAt": "2026-08-02T10:05:00Z"
}
```

The parser also accepts MockAPI's `createdAt` when `updatedAt` is absent.

## Running

```bash
flutter pub get
flutter run -t lib/main_staging.dart
```

Production entry point:

```bash
flutter run -t lib/main_production.dart
```

After changing `NoteRecord`, regenerate the Isar schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Verification

```bash
flutter analyze
flutter test -j 1
flutter build apk --debug
```

Manual offline test:

1. Launch once, then disable Wi-Fi and mobile data.
2. Create several notes and restart the app; they must still appear as pending.
3. Edit one note and delete another while offline.
4. Restore connectivity.
5. Confirm pending notes become synced and MockAPI contains the final records.
6. Restart again and confirm Isar shows the synchronized result immediately.

## Delivery guarantee

The client provides durable at-least-once upload attempts. MockAPI does not offer
an idempotency constraint, so a process crash after the server accepts `POST` but
before Isar stores the returned ID can create a duplicate. A production backend
should accept a unique client-generated ID and enforce uniqueness to make create
retries idempotent.
