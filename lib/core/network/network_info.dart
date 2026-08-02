import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

class InternetConnectionNetworkInfo implements NetworkInfo {
  InternetConnectionNetworkInfo({InternetConnection? internetConnection})
    : _internetConnection = internetConnection ?? InternetConnection();

  final InternetConnection _internetConnection;

  @override
  Future<bool> get isConnected => _internetConnection.hasInternetAccess;
}
