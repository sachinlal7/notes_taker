class RequestCancelToken {
  bool _isCancelled = false;
  final List<void Function()> _onCancel = [];

  bool get isCancelled => _isCancelled;

  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
      return;
    }

    _onCancel.add(callback);
  }

  void cancel() {
    if (_isCancelled) return;

    _isCancelled = true;
    for (final callback in _onCancel) {
      callback();
    }
    _onCancel.clear();
  }
}
