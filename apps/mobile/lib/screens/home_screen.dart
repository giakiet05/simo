import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_provider.dart';
import '../utils/localization.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'transaction_screen.dart';
import 'features_screen.dart';
import 'settings_screen.dart';
import 'transaction_form_screen.dart';

import '../widgets/voice_record_sheet.dart';

// Global key to access HomeScreen state from anywhere
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();
final GlobalKey<TransactionScreenState> transactionScreenKey = GlobalKey<TransactionScreenState>();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    TransactionScreen(key: transactionScreenKey),
    const FeaturesScreen(),
    const SettingsScreen(),
  ];

  void refreshData() {
    ref.invalidate(categoryProvider);
    ref.invalidate(transactionProvider);
    ref.invalidate(recurringProvider);
    ref.invalidate(settingsProvider);
    print('[HOME] Providers invalidated');
  }

  void switchToTransactionsTab() {
    setState(() {
      _selectedIndex = 1; // Transactions tab
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const VoiceRecordSheet(),
      );
      return;
    }

    setState(() {
      // Adjust index because of the + button at position 2
      if (index > 2) {
        _selectedIndex = index - 1;
      } else {
        _selectedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);

    // Adjust current index for display
    int displayIndex = _selectedIndex;
    if (_selectedIndex >= 2) {
      displayIndex = _selectedIndex + 1;
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          if (_selectedIndex == 1 && transactionScreenKey.currentState?.isSelectionMode == true) {
            // Let the TransactionScreen's PopScope handle it
            return;
          }
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: displayIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long),
              label: l10n.transactions,
            ),
            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: const Offset(0, 10),
                child: Transform.scale(
                  scale: 1.4,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.mic, color: Colors.white, size: 22),
                  ),
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: l10n is AppLocalizations
                  ? l10n.featuresHub
                  : (l10n.locale == 'vi' ? 'Chức năng' : 'Features'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}
