abstract interface class CrashReportingService {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  });
}
