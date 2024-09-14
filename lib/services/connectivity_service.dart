import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  void initialize(BuildContext context) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus(result, context);
      },
    );
  }

  void _updateConnectionStatus(ConnectivityResult result, BuildContext context) {
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tienes conexión a Internet.'),
          duration: Duration(hours: 1), 
        ),
      );
    } else {
      isConnected.value = true;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
