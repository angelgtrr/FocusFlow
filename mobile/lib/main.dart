import 'dart:io';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'background_tasks.dart';
import 'notifications.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await initNotifications();
    await registerProgressRefresh();
  }
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> with WidgetsBindingObserver {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState.init().then((_) => setState(() {}));
    _appState.addListener(_onStateChanged);
  }

  void _onStateChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _appState.authenticated) {
      _appState.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_appState.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_appState.authenticated) {
      return LoginScreen(appState: _appState, onSuccess: () => setState(() {}));
    }
    return HomeScreen(appState: _appState, onLoggedOut: () => setState(() {}));
  }
}
