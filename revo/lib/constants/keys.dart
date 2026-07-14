import 'package:flutter/material.dart';

/// Global key for ScaffoldMessenger to allow safe SnackBar delivery across screens
/// and prevent "removeChild" null errors on Flutter Web during navigation.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
