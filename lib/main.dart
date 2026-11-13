import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/meal_pack_provider.dart';
import 'utils/app_tokens.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file. $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MealPackProvider()..loadSavedMealPacks(),
        ),
      ],
      child: const WeeklyRecipesApp(),
    ),
  );
}

class WeeklyRecipesApp extends StatelessWidget {
  const WeeklyRecipesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextThemeLight = ThemeData.light().textTheme;
    final baseTextThemeDark = ThemeData.dark().textTheme;

    final solarisTextThemeLight = GoogleFonts.outfitTextTheme(baseTextThemeLight).copyWith(
      bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeLight.bodyLarge, color: AppTokens.textPrimaryLight, height: 1.45),
      bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeLight.bodyMedium, color: AppTokens.textPrimaryLight, height: 1.45),
      bodySmall: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeLight.bodySmall, color: AppTokens.textSecondaryLight),
      labelLarge: GoogleFonts.outfit(textStyle: baseTextThemeLight.labelLarge, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      titleLarge: GoogleFonts.outfit(textStyle: baseTextThemeLight.titleLarge, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryLight),
      titleMedium: GoogleFonts.outfit(textStyle: baseTextThemeLight.titleMedium, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryLight),
    );

    final solarisTextThemeDark = GoogleFonts.outfitTextTheme(baseTextThemeDark).copyWith(
      bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeDark.bodyLarge, color: AppTokens.textPrimaryDark, height: 1.45),
      bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeDark.bodyMedium, color: AppTokens.textPrimaryDark, height: 1.45),
      bodySmall: GoogleFonts.plusJakartaSans(textStyle: baseTextThemeDark.bodySmall, color: AppTokens.textSecondaryDark),
      labelLarge: GoogleFonts.outfit(textStyle: baseTextThemeDark.labelLarge, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      titleLarge: GoogleFonts.outfit(textStyle: baseTextThemeDark.titleLarge, fontWeight: FontWeight.w700, color: AppTokens.textPrimaryDark),
      titleMedium: GoogleFonts.outfit(textStyle: baseTextThemeDark.titleMedium, fontWeight: FontWeight.w600, color: AppTokens.textPrimaryDark),
    );

    return Consumer<MealPackProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Weekly Recipes',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          
          // --- SOLARIS GOURMET LIGHT THEME ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppTokens.bgLight,
            colorScheme: const ColorScheme.light(
              primary: AppTokens.primaryLight,
              onPrimary: Colors.white,
              primaryContainer: AppTokens.primaryContainerLight,
              onPrimaryContainer: AppTokens.primaryLight,
              secondary: AppTokens.accentSun,
              onSecondary: AppTokens.textPrimaryLight,
              surface: AppTokens.surfaceLight,
              onSurface: AppTokens.textPrimaryLight,
              outline: AppTokens.borderLight,
              error: AppTokens.errorLight,
            ),
            dividerColor: AppTokens.borderLight,
            appBarTheme: AppBarTheme(
              backgroundColor: AppTokens.bgLight,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppTokens.textPrimaryLight),
              titleTextStyle: AppTokens.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimaryLight,
                letterSpacing: -0.2,
              ),
            ),
            cardTheme: CardThemeData(
              color: AppTokens.surfaceLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                side: const BorderSide(color: AppTokens.borderLight, width: 1.0),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppTokens.surfaceLight,
              indicatorColor: AppTokens.primaryContainerLight,
              elevation: 0,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTokens.kicker(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.primaryLight);
                }
                return AppTokens.kicker(fontSize: 11, fontWeight: FontWeight.w600, color: AppTokens.textSecondaryLight);
              }),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                textStyle: AppTokens.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                elevation: 0,
              ),
            ),
            textTheme: solarisTextThemeLight,
          ),

          // --- SOLARIS GOURMET DARK THEME ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppTokens.bgDark,
            colorScheme: const ColorScheme.dark(
              primary: AppTokens.primaryDark,
              onPrimary: Colors.white,
              primaryContainer: AppTokens.primaryContainerDark,
              onPrimaryContainer: AppTokens.primaryDark,
              secondary: AppTokens.accentSunDark,
              onSecondary: Colors.white,
              surface: AppTokens.surfaceDark,
              onSurface: AppTokens.textPrimaryDark,
              outline: AppTokens.borderDark,
              error: AppTokens.errorDark,
            ),
            dividerColor: AppTokens.borderDark,
            appBarTheme: AppBarTheme(
              backgroundColor: AppTokens.bgDark,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: AppTokens.textPrimaryDark),
              titleTextStyle: AppTokens.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimaryDark,
                letterSpacing: -0.2,
              ),
            ),
            cardTheme: CardThemeData(
              color: AppTokens.surfaceDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                side: const BorderSide(color: AppTokens.borderDark, width: 1.0),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppTokens.surfaceDark,
              indicatorColor: AppTokens.primaryContainerDark,
              elevation: 0,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTokens.kicker(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.primaryDark);
                }
                return AppTokens.kicker(fontSize: 11, fontWeight: FontWeight.w600, color: AppTokens.textSecondaryDark);
              }),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                textStyle: AppTokens.display(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                elevation: 0,
              ),
            ),
            textTheme: solarisTextThemeDark,
          ),
          
          home: const MainLayout(),
        );
      },
    );
  }
}
