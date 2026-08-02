import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/notes/presentation/cubit/notes_cubit.dart';
import '../features/notes/data/notes_repository.dart';
import 'app_config.dart';
import 'app_router.dart';
import 'injection_container.dart';

class NotesTakerApp extends StatelessWidget {
  const NotesTakerApp({required this.config, this.notesRepository, super.key});

  final AppConfig config;
  final NotesRepository? notesRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NotesCubit(notesRepository ?? sl<NotesRepository>())..start(),
      child: BlocBuilder<NotesCubit, NotesState>(
        buildWhen: (previous, current) => previous.darkMode != current.darkMode,
        builder: (context, state) => MaterialApp.router(
          title: config.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: AppRouter.router(),
        ),
      ),
    );
  }
}
