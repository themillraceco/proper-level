import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/level/level_page.dart';
import 'features/clinometer/clinometer_page.dart';
import 'features/settings/settings_page.dart';

final _tabIndexProvider = StateProvider<int>((ref) => 0);

class ProperLevelApp extends StatelessWidget {
  const ProperLevelApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock status bar to match dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Proper Level',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerWidget {
  const _RootShell();

  static const _pages = [
    LevelPage(),
    ClinoPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_tabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => ref.read(_tabIndexProvider.notifier).state = i,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.straighten_outlined),
              activeIcon: Icon(Icons.straighten),
              label: 'Level',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Clinometer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
