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
import 'account_screen.dart';
import 'transaction_form_screen.dart';

// Global key để access HomeScreen state từ bất kỳ đâu
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialLoading = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionScreen(),
    const CategoryScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Auto hide loading after timeout (in case refresh is never called)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isInitialLoading) {
        setState(() => _isInitialLoading = false);
      }
    });
  }

  void startLoading() {
    if (mounted) {
      setState(() => _isInitialLoading = true);
    }
  }

  void refreshData() {
    print('[HOME] Refreshing all providers...');
    ref.invalidate(categoryProvider);
    ref.invalidate(transactionProvider);
    ref.invalidate(recurringProvider);
    ref.invalidate(settingsProvider);
    print('[HOME] Providers invalidated');

    // Hide loading overlay after refresh
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  void switchToTransactionsTab() {
    setState(() {
      _selectedIndex = 1; // Transactions tab
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Nút + ở giữa - mở form thêm transaction
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
      );
      return;
    }

    setState(() {
      // Adjust index vì nút + ở position 2
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

    // Adjust current index để hiển thị đúng tab được chọn
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
      child: Stack(
        children: [
          Scaffold(
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
                  icon: const Icon(Icons.person),
                  label: l10n.account,
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isInitialLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loadingData,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
