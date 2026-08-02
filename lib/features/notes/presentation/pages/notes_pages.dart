import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/note.dart';
import '../cubit/notes_cubit.dart';
import '../widgets/note_widgets.dart';

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  DateTime? _lastBackPress;

  void _handleBack() {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    AppSnackbar.showInfo(context, 'Press back again to exit.');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          return Scaffold(
            drawer: const _NotesDrawer(),
            appBar: AppBar(
              toolbarHeight: 64,
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: 'Open menu',
                  onPressed: Scaffold.of(context).openDrawer,
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
              title: Text(
                'Notes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Search notes',
                  onPressed: () => context.push('/notes/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: 'Sync notes',
                  onPressed: () => context.push('/notes/sync'),
                  icon: const Icon(Icons.sync_rounded),
                ),
                IconButton(
                  tooltip: 'More options',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            body: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state.isOffline
                      ? Padding(
                          key: const ValueKey('offline'),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: const OfflineBanner(),
                        )
                      : const SizedBox.shrink(key: ValueKey('online')),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 18, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Notes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Sort By Date'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.notes.isEmpty
                      ? NotesEmptyState(
                          title: 'No notes yet',
                          message:
                              'Capture your first thought and keep it available offline.',
                          icon: Icons.note_add_outlined,
                          actionLabel: 'Create note',
                          onAction: () => context.push('/notes/new'),
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<NotesCubit>().sync(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: state.notes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final note = state.notes[index];
                              return AnimatedListEntry(
                                key: ValueKey(note.id),
                                index: index,
                                child: NoteCard(
                                  note: note,
                                  onTap: () =>
                                      note.status == SyncStatus.conflict
                                      ? context.push(
                                          '/notes/${note.id}/conflict',
                                        )
                                      : context.push('/notes/${note.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            bottomNavigationBar: const OfflineBottomNavigation(
              selectedIndex: 0,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push('/notes/new'),
              tooltip: 'New note',
              child: const Icon(Icons.add_rounded, size: 32),
            ),
          );
        },
      ),
    );
  }
}

class _NotesDrawer extends StatelessWidget {
  const _NotesDrawer();

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (_) => context.pop(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 24),
          child: Text(
            'Notes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.notes_rounded),
          label: Text('All Notes'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.push_pin_outlined),
          label: Text('Pinned'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.archive_outlined),
          label: Text('Archive'),
        ),
        const Divider(indent: 16, endIndent: 16),
        const NavigationDrawerDestination(
          icon: Icon(Icons.delete_outline_rounded),
          label: Text('Trash'),
        ),
      ],
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({this.noteId, super.key});

  final String? noteId;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.noteId == null
        ? null
        : context.read<NotesCubit>().byId(widget.noteId!);
    _titleController = TextEditingController(text: note?.title);
    _bodyController = TextEditingController(text: note?.body);
    _titleController.addListener(_markDirty);
    _bodyController.addListener(_markDirty);
  }

  void _markDirty() {
    if (mounted) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _discard() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<NotesCubit>();
    if (widget.noteId == null) {
      await cubit.create(
        title: _titleController.text,
        body: _bodyController.text,
      );
    } else {
      await cubit.update(
        id: widget.noteId!,
        title: _titleController.text,
        body: _bodyController.text,
      );
    }
    if (!mounted) return;
    _dirty = false;
    AppSnackbar.showSuccess(
      context,
      widget.noteId == null ? 'Note created.' : 'Note updated.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;
    final offline = context.select((NotesCubit cubit) => cubit.state.isOffline);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          leading: IconButton(
            tooltip: 'Cancel',
            onPressed: _discard,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            isEditing ? 'Edit Note' : 'New Note',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Chip(
              avatar: const Icon(Icons.sync_rounded, size: 14),
              label: Text(
                'Saved',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              side: BorderSide.none,
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        bottomNavigationBar: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            top: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  for (final icon in const [
                    Icons.format_bold_rounded,
                    Icons.format_italic_rounded,
                    Icons.format_list_bulleted_rounded,
                    Icons.check_box_outlined,
                    Icons.link_rounded,
                  ])
                    IconButton(onPressed: () {}, icon: Icon(icon)),
                  const Spacer(),
                  Text(
                    '${_bodyController.text.trim().isEmpty ? 0 : _bodyController.text.trim().split(RegExp(r'\s+')).length} words',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (offline)
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const ListTile(
                  dense: true,
                  leading: Icon(Icons.cloud_off_rounded),
                  title: Text(
                    'Changes will sync when internet becomes available.',
                  ),
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            DateFormat(
                              'MMM d, yyyy • h:mm a',
                            ).format(DateTime.now()),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          side: BorderSide.none,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _titleController,
                      autofocus: !isEditing,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Title is required.'
                          : null,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _bodyController,
                      minLines: 14,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Start writing…',
                        filled: false,
                        border: InputBorder.none,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Note body is required.'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteDetailsPage extends StatelessWidget {
  const NoteDetailsPage({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    final note = context.select((NotesCubit cubit) => cubit.byId(noteId));
    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const NotesEmptyState(
          title: 'Note not found',
          message: 'This note may have been deleted.',
          icon: Icons.find_in_page_outlined,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share note',
            onPressed: () => AppSnackbar.showInfo(context, 'Share is ready.'),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Delete note',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Sync status',
            onPressed: () => context.push('/notes/sync'),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const OfflineBottomNavigation(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit note',
        onPressed: () => context.push('/notes/$noteId/edit'),
        child: const Icon(Icons.edit_rounded),
      ),
      body: Hero(
        tag: 'note-$noteId',
        child: Material(
          color: Colors.transparent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              SyncStatusBadge(status: note.status),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        note.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      _Metadata(
                        label: 'Created',
                        value: DateFormat.yMMMd().format(note.updatedAt),
                      ),
                      _Metadata(
                        label: 'Updated',
                        value: DateFormat.yMMMd().format(note.updatedAt),
                      ),
                      _Metadata(label: 'Version', value: 'V${note.version}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true && context.mounted) {
      await context.read<NotesCubit>().delete(noteId);
      if (!context.mounted) return;
      context.go('/notes');
    }
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class NotesSearchPage extends StatefulWidget {
  const NotesSearchPage({super.key});

  @override
  State<NotesSearchPage> createState() => _NotesSearchPageState();
}

class _NotesSearchPageState extends State<NotesSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesCubit>().state.notes;
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? notes
        : notes
              .where(
                (note) =>
                    note.title.toLowerCase().contains(query) ||
                    note.body.toLowerCase().contains(query),
              )
              .toList();
    return _BackToNotesOnPop(
      child: Scaffold(
        bottomNavigationBar: const OfflineBottomNavigation(selectedIndex: 1),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchBar(
                  controller: _controller,
                  hintText: 'Search your notes',
                  leading: IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go('/notes'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      tooltip: 'Sync',
                      onPressed: () => context.push('/notes/sync'),
                      icon: const Icon(Icons.sync_rounded),
                    ),
                  ],
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF287D49),
                    ),
                    label: Text(
                      '${notes.length} notes • Available offline',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? const NotesEmptyState(
                        title: 'No results',
                        message: 'Try a different title or keyword.',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => NoteCard(
                          note: results[index],
                          onTap: () =>
                              results[index].status == SyncStatus.conflict
                              ? context.push(
                                  '/notes/${results[index].id}/conflict',
                                )
                              : context.push('/notes/${results[index].id}'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncProgressPage extends StatefulWidget {
  const SyncProgressPage({super.key});

  @override
  State<SyncProgressPage> createState() => _SyncProgressPageState();
}

class _SyncProgressPageState extends State<SyncProgressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotesCubit>().sync(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: const OfflineBottomNavigation(selectedIndex: 0),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final failed = state.syncPhase == SyncPhase.failed;
          final complete = state.syncPhase == SyncPhase.complete;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.circle,
                      size: 8,
                      color: failed
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text(
                      failed ? 'SYNC PAUSED' : 'SYNCING IN PROGRESS',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    side: BorderSide.none,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: failed ? 0 : state.syncProgress,
                                    strokeWidth: 8,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${((failed ? 0 : state.syncProgress) * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      'Overall',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            failed
                                ? 'Synchronization failed'
                                : complete
                                ? 'All notes are synchronized'
                                : 'Synchronizing Your Vault',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your local changes are being merged with the cloud. This usually takes a few seconds.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          ...SyncPhase.values
                              .where(
                                (phase) =>
                                    phase.index > 0 &&
                                    phase.index < SyncPhase.complete.index,
                              )
                              .map(
                                (phase) => _SyncStep(
                                  label: _phaseLabel(phase),
                                  complete: state.syncPhase.index > phase.index,
                                  active: state.syncPhase == phase,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  if (failed) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<NotesCubit>().sync(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _phaseLabel(SyncPhase phase) => switch (phase) {
    SyncPhase.idle => 'Preparing synchronization',
    SyncPhase.uploading => 'Uploading local changes',
    SyncPhase.downloading => 'Downloading latest notes',
    SyncPhase.resolving => 'Resolving conflicts',
    SyncPhase.complete => 'Complete',
    SyncPhase.failed => 'Failed',
  };
}

class _SyncStep extends StatelessWidget {
  const _SyncStep({
    required this.label,
    required this.complete,
    required this.active,
  });

  final String label;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: complete || active
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        complete
            ? Icons.check_rounded
            : active
            ? Icons.sync_rounded
            : Icons.more_horiz_rounded,
        size: 18,
      ),
    ),
    title: Text(label),
  );
}

class ConflictResolutionPage extends StatelessWidget {
  const ConflictResolutionPage({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    final note = context.watch<NotesCubit>().byId(noteId);
    if (note == null) {
      return const Scaffold(
        body: NotesEmptyState(
          title: 'No conflict',
          message: 'This note no longer exists.',
          icon: Icons.task_alt_rounded,
        ),
      );
    }
    final serverBody = note.serverBody ?? note.body;
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve conflict')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose the version to keep',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Differences are highlighted so nothing is lost.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _VersionCard(
            label: 'Local version',
            body: note.body,
            color: const Color(0xFFE8F1FF),
          ),
          const SizedBox(height: 12),
          _VersionCard(
            label: 'Server version',
            body: serverBody,
            color: const Color(0xFFFFECEA),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _resolve(context, note.body),
            child: const Text('Keep local'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _resolve(context, serverBody),
            child: const Text('Keep server'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/notes/$noteId/merge'),
            icon: const Icon(Icons.merge_rounded),
            label: const Text('Merge manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(BuildContext context, String body) async {
    await context.read<NotesCubit>().resolveConflict(noteId, body);
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Conflict resolved.');
    context.go('/notes/$noteId');
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.label,
    required this.body,
    required this.color,
  });

  final String label;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              body,
              style: const TextStyle(color: Color(0xFF191C21), height: 1.45),
            ),
          ),
        ],
      ),
    ),
  );
}

class MergeNotePage extends StatefulWidget {
  const MergeNotePage({required this.noteId, super.key});

  final String noteId;

  @override
  State<MergeNotePage> createState() => _MergeNotePageState();
}

class _MergeNotePageState extends State<MergeNotePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final note = context.read<NotesCubit>().byId(widget.noteId);
    _controller = TextEditingController(
      text: '${note?.body ?? ''}\n\n${note?.serverBody ?? ''}'.trim(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merge note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit the combined version',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(hintText: 'Merged content'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (_controller.text.trim().isEmpty) {
                  AppSnackbar.showError(
                    context,
                    'Merged note cannot be empty.',
                  );
                  return;
                }
                await context.read<NotesCubit>().resolveConflict(
                  widget.noteId,
                  _controller.text,
                );
                if (!context.mounted) return;
                context.go('/notes/${widget.noteId}');
              },
              icon: const Icon(Icons.merge_rounded),
              label: const Text('Save merge'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotesCubit>().state;
    return _BackToNotesOnPop(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: Text(
            'Notes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Sync',
              onPressed: () => context.push('/notes/sync'),
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        bottomNavigationBar: const OfflineBottomNavigation(selectedIndex: 2),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SettingsSection(
              title: 'CONNECTIVITY',
              children: [
                ListTile(
                  leading: const Icon(Icons.wifi_rounded),
                  title: const Text('Network Status'),
                  subtitle: const Text('Automatic background synchronization'),
                  trailing: Text(
                    state.isOffline ? 'Offline' : 'Online',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Reduces eye strain at night'),
                  value: state.darkMode,
                  onChanged: context.read<NotesCubit>().setDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SettingsSection(
              title: 'STORAGE & CACHE',
              children: [
                ListTile(
                  leading: Icon(Icons.storage_rounded),
                  title: Text('Database'),
                  subtitle: Text(
                    'Notes are stored locally and synchronized automatically',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'SYNC & DATA',
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Pending Sync'),
                  subtitle: Text(
                    '${state.pendingCount} items waiting for connection',
                  ),
                  trailing: const Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.sync_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Manual Sync Now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  subtitle: const Text('Force sync with remote server'),
                  onTap: () => context.push('/notes/sync'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    'v${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackToNotesOnPop extends StatelessWidget {
  const _BackToNotesOnPop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go('/notes');
    },
    child: child,
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: .8,
            ),
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
