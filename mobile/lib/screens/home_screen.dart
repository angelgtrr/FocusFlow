import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import 'daily_page.dart';
import 'dimensions_page.dart';
import 'tasks_page.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onLoggedOut;
  const HomeScreen({super.key, required this.appState, required this.onLoggedOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _logout() async {
    await widget.appState.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final titles = ['Daily', 'Dimensions', 'Tasks'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: appState.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${appState.error}',
                  style: const TextStyle(color: AppColors.rose400),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : IndexedStack(
              index: _index,
              children: [
                DailyPage(appState: appState),
                DimensionsPage(appState: appState),
                TasksPage(appState: appState),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Daily'),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dimensions',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
