import 'package:flutter/material.dart';

import '../app_state.dart';
import '../backup.dart';
import '../greeting.dart';
import '../theme.dart';
import 'daily_page.dart';
import 'dates_page.dart';
import 'dimensions_page.dart';
import 'tasks_page.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.appState.userName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) promptForName(context, widget.appState);
      });
    }
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
            onPressed: () => exportBackupWithFeedback(context, appState),
            icon: const Icon(Icons.upload_outlined, size: 20),
            tooltip: 'Export backup',
          ),
          IconButton(
            onPressed: () => pickAndRestoreBackup(context, appState),
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: 'Import backup',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
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
