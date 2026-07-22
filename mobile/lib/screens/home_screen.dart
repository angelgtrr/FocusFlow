import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import 'daily_page.dart';
import 'dates_page.dart';
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
    final titles = ['Daily', 'Dimensions', 'Tasks', 'Dates'];

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
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _SyncBanner(offline: appState.offline, pendingCount: appState.pendingOpsCount),
            Expanded(
              child: appState.error != null
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
                        DatesPage(appState: appState),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: NavigationBar(
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
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Dates',
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final bool offline;
  final int pendingCount;

  const _SyncBanner({required this.offline, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    if (!offline && pendingCount == 0) return const SizedBox.shrink();

    final String label;
    final IconData icon;
    final Color color;
    if (offline) {
      label = pendingCount > 0
          ? 'Offline · $pendingCount change${pendingCount == 1 ? '' : 's'} will sync when you\'re back online'
          : 'Offline · showing your last synced data';
      icon = Icons.cloud_off_outlined;
      color = AppColors.amber500;
    } else {
      label = 'Syncing $pendingCount change${pendingCount == 1 ? '' : 's'}...';
      icon = Icons.cloud_sync_outlined;
      color = AppColors.violet400;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }
}
