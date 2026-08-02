enum SocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  authFailed,
  failed;

  bool get isConnected => this == connected;

  bool get isConnecting => this == connecting || this == reconnecting;

  bool get isDisconnected => this == disconnected;

  bool get canSend => this == connected;
}
