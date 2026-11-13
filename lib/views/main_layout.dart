import 'package:flutter/material.dart';
import '../utils/app_tokens.dart';
import 'dashboard_view.dart';
import 'recipe_library_view.dart';
import 'grocery_list_view.dart';
import 'saved_recipes_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardView(),
    RecipeLibraryView(),
    GroceryListView(),
    SavedRecipesView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0A000000),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined, size: 22),
                selectedIcon: Icon(Icons.wb_sunny_rounded, size: 22),
                label: 'Planner',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, size: 22),
                selectedIcon: Icon(Icons.menu_book_rounded, size: 22),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined, size: 22),
                selectedIcon: Icon(Icons.shopping_bag_rounded, size: 22),
                label: 'Groceries',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_outline_rounded, size: 22),
                selectedIcon: Icon(Icons.bookmark_rounded, size: 22),
                label: 'Saved',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
