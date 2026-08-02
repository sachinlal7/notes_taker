# 🏗 Project Architecture & Development Rules

Architecture:

```text
Clean Architecture + BLoC/Cubit + Feature-Based Modular Structure + GoRouter + .env Config
```

Core flow:

```text
Page / Widget
→ BLoC / Cubit
→ UseCase
→ Repository Interface
→ Repository Implementation
→ DataSource
→ ApiClient / WebSocket / Firebase / Local Storage
```

---

# 1. Final Project Structure

```text
project_name/
├── README.md
├── AGENTS.md
├── PROJECT_RULES.md
├── pubspec.yaml
├── analysis_options.yaml
├── .env.staging
├── .env.production
│
├── android/
├── ios/
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── lottie/
│   ├── sounds/
│   └── videos/
│
└── lib/
    ├── main.dart
    ├── main_staging.dart
    ├── main_production.dart
    │
    ├── app/
    │   ├── app.dart
    │   ├── app_config.dart
    │   ├── app_router.dart
    │   ├── injection_container.dart
    │   └── bloc_observer.dart
    │
    ├── core/
    │   ├── constants/
    │   │   ├── api_constants.dart
    │   │   ├── app_constants.dart
    │   │   ├── asset_constants.dart
    │   │   └── route_constants.dart
    │   │
    │   ├── env/
    │   │   ├── env_keys.dart
    │   │   └── env_loader.dart
    │   │
    │   ├── errors/
    │   │   ├── exceptions.dart
    │   │   ├── failures.dart
    │   │   └── error_mapper.dart
    │   │
    │   ├── network/
    │   │   ├── api_client.dart
    │   │   ├── dio_client.dart
    │   │   ├── api_response.dart
    │   │   ├── network_info.dart
    │   │   └── request_cancel_token.dart
    │   │
    │   ├── storage/
    │   │   ├── local_storage.dart
    │   │   ├── secure_storage.dart
    │   │   └── storage_keys.dart
    │   │
    │   ├── auth/
    │   │   ├── auth_session.dart
    │   │   ├── token_manager.dart
    │   │   └── session_guard.dart
    │   │
    │   ├── permissions/
    │   │   └── permission_service.dart
    │   │
    │   ├── realtime/
    │   │   ├── websocket_service.dart
    │   │   ├── socket_status.dart
    │   │   ├── socket_message.dart
    │   │   ├── socket_event_router.dart
    │   │   └── socket_error_mapper.dart
    │   │
    │   ├── location/
    │   │   └── location_service.dart
    │   │
    │   ├── lifecycle/
    │   │   └── app_lifecycle_service.dart
    │   │
    │   ├── monitoring/
    │   │   ├── crash_reporting_service.dart
    │   │   └── logger.dart
    │   │
    │   ├── theme/
    │   │   ├── app_theme.dart
    │   │   ├── app_colors.dart
    │   │   └── app_text_styles.dart
    │   │
    │   ├── utils/
    │   │   ├── validators.dart
    │   │   ├── date_time_utils.dart
    │   │   ├── debouncer.dart
    │   │   └── helpers.dart
    │   │
    │   └── widgets/
    │       ├── app_button.dart
    │       ├── app_text_field.dart
    │       ├── app_loader.dart
    │       ├── app_snackbar.dart
    │       ├── error_view.dart
    │       └── empty_view.dart
    │
    ├── shared/
    │   ├── entities/
    │   │   └── user_entity.dart
    │   └── widgets/
    │       └── app_scaffold.dart
    │
    └── features/
        ├── splash/
        │   └── presentation/
        │       └── pages/
        │           └── splash_page.dart
        │
        ├── auth/
        │   ├── data/
        │   │   ├── datasources/
        │   │   ├── models/
        │   │   └── repositories/
        │   ├── domain/
        │   │   ├── entities/
        │   │   ├── repositories/
        │   │   └── usecases/
        │   └── presentation/
        │       ├── bloc/
        │       ├── pages/
        │       └── widgets/
        │
        ├── dashboard/
        │   └── presentation/
        │       ├── bloc/
        │       ├── pages/
        │       └── widgets/
        │
        └── profile/
            ├── data/
            ├── domain/
            └── presentation/
                ├── bloc/
                ├── pages/
                └── widgets/
```

Removed from base structure:

```text
intel
sos
notifications
reports
settings
l10n
pagination_model
refresh_token_usecase
```

Add these later only when the project actually needs them.

---

# 2. Dependency Direction Rules

Allowed:

```text
presentation → domain
data → domain
presentation → core
data → core
domain → core only for pure shared abstractions
```

Forbidden:

```text
presentation → data
domain → data
domain → presentation
data → presentation
```

Strict rules:

- UI must not call API directly.
- UI must not call Firebase directly.
- UI must not open WebSocket directly.
- UI must not use local storage directly.
- BLoC/Cubit must not call Dio directly.
- BLoC/Cubit must not call Firebase directly.
- BLoC/Cubit must not parse raw API/socket responses.
- BLoC/Cubit must call UseCase only.
- UseCase must call Repository interface only.
- Repository implementation must call DataSource.
- DataSource must call ApiClient / Firebase / WebSocket / Local Storage.

---

# 3. Feature Development Rules

One business module should be one feature.

Do not create one feature folder per screen.

Wrong:

```text
features/profile_details/
features/profile_edit/
features/profile_success/
```

Correct:

```text
features/profile/
└── presentation/
    ├── pages/
    │   ├── profile_page.dart
    │   ├── edit_profile_page.dart
    │   └── profile_success_page.dart
    ├── bloc/
    └── widgets/
```

Standard major feature structure:

```text
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

For UI-only features, do not force `data/` and `domain/`.

Example:

```text
features/splash/
└── presentation/
    └── pages/
        └── splash_page.dart
```

---

# 4. BLoC / Cubit Rules

This project uses `flutter_bloc`.

Use Cubit for:

- simple API fetch
- simple form submission
- simple CRUD operation
- one primary action
- linear screen state

Use BLoC for:

- 3+ distinct events
- event chaining
- complex state machine
- realtime stream handling
- multi-step workflow
- multiple actions in the same flow

Main rule:

```text
One screen ≠ one BLoC
One business flow/state = one BLoC/Cubit
```

Do not create separate BLoC/Cubit for:

- success page
- static page
- placeholder page
- local UI-only page

A feature may contain both Cubit and BLoC only if they manage separate flows.

Wrong:

```text
LoginBloc and LoginCubit both managing login state
```

Allowed:

```text
ProfileCubit → profile fetch/update
PasswordResetBloc → OTP/password reset flow
```

---

# 5. Global Error Handling Rules

Core principle:

```text
UI must never display raw exceptions, Dio errors, socket errors, backend stack traces, or unknown server responses.
```

Required flow:

```text
API / Dio / Firebase / Socket
↓
DataSource throws Exception
↓
Repository catches Exception
↓
ErrorMapper converts to Failure
↓
BLoC/Cubit emits Failure State
↓
UI listens using BlocListener
↓
Global AppSnackbar shows safe message
```

Forbidden:

- Showing raw exception on UI
- Showing DioException text on UI
- Showing stack trace on UI
- Showing backend technical messages on UI
- Showing API/server errors inline inside screen body
- Using `error.toString()` in BLoC/Cubit state
- Building error text inside widgets manually
- Showing `Null check operator used on a null value`
- Showing `type 'Null' is not a subtype of type...`
- Showing `Internal server error`
- Showing `SocketException`
- Showing `TimeoutException`
- Showing `FormatException`

Approved safe messages:

```text
No internet connection. Please check your network and try again.
Network is slow. Please try again.
Something went wrong. Please try again.
Unable to process request. Please try again.
Your session has expired. Please sign in again.
Live updates are temporarily unavailable.
Reconnecting to live updates...
```

Approved business messages may be shown only if they are user-facing:

```text
Invalid email or password.
Invalid OTP.
Email already registered.
Account not verified.
Incorrect password.
Required field missing.
```

Inline errors are allowed only for form validation:

```text
Email is required.
Password must be at least 6 characters.
Invalid phone number.
This field is required.
```

---

# 6. Snackbar / Toast Rules

All API/system/realtime errors must be shown through the global snackbar only.

Use:

```text
core/widgets/app_snackbar.dart
```

Required:

- Use `BlocListener` or `BlocConsumer.listener` for failure states.
- Use one shared snackbar helper.
- Do not create custom snackbar styling per screen.
- Do not show raw errors in widgets.
- Do not show API errors as inline text.
- Do not show cancellation errors.
- Do not show empty error messages.

Correct:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthFailure) {
      AppSnackbar.showError(context, state.message);
    }
  },
  child: const LoginForm(),
)
```

Wrong:

```dart
if (state is AuthFailure) {
  return Text(state.message);
}
```

Global snackbar example:

```dart
import 'package:flutter/material.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError(BuildContext context, String message) {
    if (message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    if (message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showInfo(BuildContext context, String message) {
    if (message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
```

---

# 7. API Integration Rules

Required flow:

```text
Cubit/Bloc
↓
UseCase
↓
Repository Interface
↓
Repository Implementation
↓
RemoteDataSource
↓
ApiClient
↓
Dio
```

Forbidden:

- Hardcoded URLs inside features
- API calls inside UI
- API calls inside BLoC/Cubit
- Direct Dio usage inside features
- Exposing raw error stack traces
- Duplicate API logic
- Showing backend error raw message without mapping
- Leaving requests running unnecessarily after page close

Repository/usecase should return a safe result type.

Example:

```dart
typedef Result<T> = Future<({Failure? failure, T? data})>;
```

or:

```text
Either<Failure, T>
```

Cancellation rule:

- Do not expose Dio-specific `CancelToken` into domain business logic.
- If request cancellation is needed, keep it in data/network layer or use an app-defined abstraction like `RequestCancelToken`.

---

# 8. Environment / .env Rules

The app uses `.env` files for raw environment values.

Examples:

```text
.env.staging
.env.production
```

`.env` stores raw values:

```env
APP_ENV=staging
APP_NAME=My App Staging
BASE_URL=https://staging-api.example.com
SOCKET_URL=wss://staging-socket.example.com
ENABLE_LOGGING=true
ENABLE_CRASH_REPORTING=false
SENTRY_DSN=
```

`env_keys.dart` stores key names only.

`env_loader.dart` reads `.env`, validates values, converts strings into Dart types, and returns `AppConfig`.

`app_config.dart` gives typed config to the app.

Important:

```text
.env in Flutter is not fully secret. Values can be reverse-engineered.
```

Allowed in `.env`:

```text
BASE_URL
SOCKET_URL
SENTRY_DSN
GOOGLE_MAPS_PUBLIC_KEY
FIREBASE_CONFIG
ENVIRONMENT_NAME
FEATURE_FLAGS
```

Forbidden in `.env`:

```text
backend private keys
admin tokens
database passwords
payment secret keys
Firebase service account keys
Twilio secret keys
server signing keys
```

Secrets must stay on the backend.

---

# 9. Authentication / Session Rules

Base auth feature includes:

```text
login_usecase.dart
logout_usecase.dart
get_current_user_usecase.dart
```

No `refresh_token_usecase.dart` unless backend supports a refresh-token API.

If no refresh token exists and API returns 401:

```text
clear local session
disconnect socket if connected
redirect to login
show snackbar: Your session has expired. Please sign in again.
```

Token rules:

- Store access token in secure storage only.
- Never store token in SharedPreferences.
- Never print token.
- Never show token in UI.
- Clear token on logout.
- Clear token on unauthorized session expiry.

---

# 10. GoRouter / Shell Route Rules

Use GoRouter for centralized navigation.

Use `StatefulShellRoute.indexedStack` for post-login bottom navigation shell when tab state must be preserved.

Shell structure:

```text
MainShellScreen
├── AppBar
├── Drawer
├── Current selected branch/page
└── BottomNavigationBar
```

Each `StatefulShellBranch` represents one bottom navigation tab.

`StatefulShellRoute.indexedStack` preserves:

- scroll position
- loaded state
- nested navigation stack
- tab state

Branch order rule:

Keep branch order same as bottom navigation order where possible.

Preferred:

```text
Bottom Nav index 0 → Branch 0
Bottom Nav index 1 → Branch 1
Bottom Nav index 2 → Branch 2
```

Avoid unnecessary mapping functions unless design order and route branch order must differ.

If mapping is needed, document it clearly.

Back button rule for logged-in shell:

```text
If drawer open → close drawer
If user is not on home tab → go to home tab
If user is on home tab → first back shows snackbar
Second back within 2 seconds → close app
```

Use global snackbar:

```dart
AppSnackbar.showInfo(
  context,
  'Press back again to close the app',
);
```

Do not create custom snackbars directly inside shell.

Tab reset/refresh rule:

Avoid timestamp query reset unless full screen recreation is intentionally required.

Prefer:

```dart
navigationShell.goBranch(
  branchIndex,
  initialLocation: branchIndex == navigationShell.currentIndex,
);
```

Timestamp reset is allowed only with clear reason:

```dart
context.go('/some-route?reset=${DateTime.now().microsecondsSinceEpoch}');
```

Placeholder screen rule:

- Placeholder screens are allowed only for unfinished modules.
- They must not contain fake business logic.

---

# 11. WebSocket Rules

WebSocket is an enhancement layer for realtime updates. It must not replace HTTP architecture.

Standard pattern:

```text
HTTP = initial fetch + fallback sync + recovery
WebSocket = incremental live updates only
```

Good use cases:

- status updates
- notification counters
- dashboard live values
- device/sensor updates
- progress updates

Bad use cases:

- replacing all CRUD APIs
- fetching initial page data only through socket
- one-time form submissions
- one socket per screen

One shared connection rule:

Use one central `WebSocketService` per authenticated app session unless backend explicitly requires otherwise.

Forbidden:

- socket connection in widget `build()`
- direct WebSocket usage inside widgets
- raw JSON parsing inside presentation widgets
- one socket per screen by default
- blind reconnect on auth failure

Message validation rule:

Every incoming socket message must be validated before use.

Reconnect rule:

- unexpected disconnect → reconnect with backoff
- manual disconnect → do not reconnect

Manual disconnect examples:

```text
logout
session reset
explicit teardown
```

After reconnect, critical features should resync using HTTP to avoid missed updates.

---

# 12. Security Rules

Never place these inside Flutter app or `.env`:

```text
backend private keys
admin tokens
database passwords
payment secret keys
Twilio secret keys
Firebase service account keys
server signing keys
```

Use only in production:

```text
https://
wss://
```

Never use in production:

```text
http://
ws://
```

Never log:

```text
tokens
passwords
OTP
private user data
full sensitive request body
socket auth payload
secret keys
```

Reverse engineering rule:

```text
Assume everything inside the mobile app can be seen.
```

Security must be enforced on backend using:

- authentication
- authorization
- role checks
- request ownership checks
- rate limiting
- session validation

Release build protection:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

---

# 13. Crash Reporting / Monitoring Rules

Crash reporting must be implemented behind the shared abstraction:

```text
core/monitoring/crash_reporting_service.dart
```

Feature code, BLoC/Cubit, repositories, data sources, widgets, and use cases must not import crash provider SDKs directly.

Allowed:

```text
CrashReportingService
Logger
```

Forbidden outside `core/monitoring/` and `app/injection_container.dart`:

```text
FirebaseCrashlytics.instance
Sentry.captureException
provider-specific crash SDK calls
```

Provider implementation pattern:

```text
CrashReportingService interface
↓
FirebaseCrashReportingService OR SentryCrashReportingService
↓
Provider SDK
```

Example files when provider is added:

```text
core/monitoring/firebase_crash_reporting_service.dart
core/monitoring/sentry_crash_reporting_service.dart
```

Switching providers must require changing only:

```text
pubspec.yaml
app startup/provider initialization
app/injection_container.dart registration
provider implementation file
```

Feature/domain/data/presentation code must continue calling only:

```dart
crashReportingService.recordError(error, stackTrace);
```

Crash reporting must not send:

- access tokens
- refresh tokens
- passwords
- OTP values
- secret keys
- full sensitive request bodies
- socket auth payloads
- private user data unless explicitly approved and sanitized

Use `Logger` for local debug logs and `CrashReportingService` for production crash/error reporting.

Recommended provider behavior:

- initialize the provider in app startup before `runApp`
- enable provider reporting only for staging/production when configured
- disable or reduce reporting in local development
- record Flutter framework errors
- record platform dispatcher uncaught errors
- record BLoC/Cubit uncaught errors through `AppBlocObserver`
- set user id only after authentication and clear it on logout
- attach only safe custom keys such as app version, environment, feature name, and non-sensitive status codes

If adding Firebase Crashlytics:

- add Firebase initialization before registering `FirebaseCrashReportingService`
- keep all `firebase_crashlytics` imports inside `core/monitoring/`
- do not call Crashlytics directly from feature code

If adding Sentry:

- initialize Sentry in app startup before `runApp`
- keep all `sentry_flutter` imports inside `core/monitoring/` and startup wiring
- do not call Sentry directly from feature code

Testing expectations when crash reporting is added:

- verify `CrashReportingService.recordError` is called for uncaught app errors where applicable
- verify sensitive values are not sent in error messages, tags, breadcrumbs, or custom data
- verify provider swapping does not require changing feature code

---

# 14. Lifecycle Cleanup Rules

Any feature using these must clean up properly:

```text
camera
microphone
location stream
socket subscription
timer
animation controller
stream subscription
pending request
```

Required cleanup:

- cancel StreamSubscription
- dispose TextEditingController
- dispose AnimationController
- stop location tracking
- unsubscribe socket channel if required
- cancel timers
- cancel pending API request where applicable

Cleanup locations:

```text
Cubit/Bloc close()
StatefulWidget dispose()
App lifecycle handler if required
```

---

# 15. Code Quality Rules

Naming:

```text
Classes → PascalCase
Variables → camelCase
Files → snake_case
Folders → lowercase
```

Target limits:

```text
File: ideally under 300 lines
Function: ideally under 50 lines
Nesting: max 3 where possible
Parameters: prefer max 4
```

Before commit:

```bash
flutter analyze
```

Also check:

- no debug prints in production code
- no raw errors shown on UI
- no commented dead code
- no unresolved release-critical TODO
- no direct Dio call in UI/BLoC
- no direct Firebase call in UI/BLoC
- no token logs
- no hardcoded API URL in features

`setState` rule:

Do not use `setState` for:

- API loading
- API success/failure
- business state
- socket state
- navigation decision state
- persistent state

Allowed only for local ephemeral UI state:

- password visibility toggle
- animation-only UI
- expansion tile local state
- temporary focus/hover UI

If local UI state grows, move it to Cubit/BLoC.

---

# 16. Testing Rules

Minimum expected tests:

Domain:

- usecase tests
- repository contract behavior if needed

Data:

- datasource parsing tests
- repository error mapping tests
- invalid response tests

Presentation:

- BLoC/Cubit loading, success, failure tests
- form validation state tests

Routing:

- shell initial route
- bottom nav branch switching
- protected route redirection if implemented

Error handling:

- DioException maps to safe failure
- 401 maps to UnauthorizedFailure
- timeout maps to TimeoutFailure
- raw exception never reaches UI state

WebSocket if used:

- successful connection
- unexpected disconnect
- reconnect
- auth failure
- malformed message
- unknown event
- duplicate event
- out-of-order event
- HTTP resync after reconnect

---

# 17. Final Golden Rules

1. UI never calls API directly.
2. UI never opens socket directly.
3. UI never displays raw errors.
4. All API/system errors show through global snackbar only.
5. Inline errors are only for form validation.
6. BLoC/Cubit never calls Dio/Firebase/socket directly.
7. BLoC/Cubit calls UseCase only.
8. UseCase calls Repository interface only.
9. Repository implementation calls DataSource.
10. DataSource calls ApiClient/Firebase/WebSocket/local storage.
11. One feature means one business module, not one screen.
12. One BLoC/Cubit means one state/business flow, not one screen.
13. Success pages usually do not need BLoC/Cubit.
14. Keep feature-specific code inside the feature.
15. Keep shared/global code inside core/shared.
16. Use lowercase folder names.
17. Do not import data layer into presentation.
18. Use Entity outside data layer.
19. Use Model only inside data layer.
20. Secrets must never be stored inside Flutter app.
21. `.env` is for public config, not private secrets.
22. Production logs must not expose sensitive data.
23. GoRouter navigation must be centralized.
24. Bottom navigation shell should use `StatefulShellRoute.indexedStack` when tab state must be preserved.
25. Manual snackbars are forbidden; use `AppSnackbar`.
26. Crash reporting providers must be hidden behind `CrashReportingService`.
27. Firebase Crashlytics/Sentry must not be imported directly in feature code.
