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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(isDark),
          border: Border(
            top: BorderSide(
              color: AppTokens.border(isDark),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            elevation: 0,
            height: 66,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined, size: 20),
                selectedIcon: Icon(Icons.calendar_today_rounded, size: 20),
                label: 'Planner',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, size: 21),
                selectedIcon: Icon(Icons.menu_book_rounded, size: 21),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined, size: 21),
                selectedIcon: Icon(Icons.shopping_bag_rounded, size: 21),
                label: 'Groceries',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded, size: 21),
                selectedIcon: Icon(Icons.bookmark_rounded, size: 21),
                label: 'Saved',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
