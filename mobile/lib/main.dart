import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.init().then((_) => setState(() {}));
    _appState.addListener(_onStateChanged);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
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
