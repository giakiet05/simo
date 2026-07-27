import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'transaction_screen.dart';
import 'category_screen.dart';
import 'settings_screen.dart';
import 'transaction_form_screen.dart';

// Global key to access HomeScreen state from anywhere
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionScreen(),
    const CategoryScreen(),
    const SettingsScreen(),
  ];

  void refreshData() {
    print('[HOME] Refreshing all providers...');
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
      // + button in the middle - open transaction form
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
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
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
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
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.category),
              label: l10n.categories,
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
