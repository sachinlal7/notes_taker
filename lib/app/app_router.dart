import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_constants.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/notes/presentation/pages/notes_pages.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.splash,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(path: RouteConstants.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: RouteConstants.notes,
        pageBuilder: (_, state) => _page(state, const NotesHomePage()),
      ),
      GoRoute(
        path: RouteConstants.createNote,
        pageBuilder: (_, state) => _page(state, const NoteEditorPage()),
      ),
      GoRoute(
        path: RouteConstants.searchNotes,
        pageBuilder: (_, state) => _page(state, const NotesSearchPage()),
      ),
      GoRoute(
        path: RouteConstants.sync,
        pageBuilder: (_, state) => _page(state, const SyncProgressPage()),
      ),
      GoRoute(
        path: '/notes/:id/edit',
        pageBuilder: (_, state) =>
            _page(state, NoteEditorPage(noteId: state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/notes/:id/conflict',
        pageBuilder: (_, state) => _page(
          state,
          ConflictResolutionPage(noteId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/notes/:id/merge',
        pageBuilder: (_, state) =>
            _page(state, MergeNotePage(noteId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/notes/:id',
        pageBuilder: (_, state) =>
            _page(state, NoteDetailsPage(noteId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: RouteConstants.settings,
        pageBuilder: (_, state) => _page(state, const SettingsPage()),
      ),
      GoRoute(
        path: RouteConstants.states,
        pageBuilder: (_, state) => _page(state, const StatesGalleryPage()),
      ),
    ],
  );

  static CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween(
          begin: const Offset(.04, .02),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(offset),
            child: child,
          ),
        );
      },
    );
  }

  static GoRouter router() => _router;

  static void goToLogin() {
    _router.go(RouteConstants.login);
  }
}
