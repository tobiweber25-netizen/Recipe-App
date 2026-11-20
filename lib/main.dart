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

  ThemeData _buildTheme({required bool isDark}) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final baseText = baseTheme.textTheme;

    final bg = AppTokens.bg(isDark);
    final surface = AppTokens.surface(isDark);
    final surfaceMuted = AppTokens.surfaceMuted(isDark);
    final border = AppTokens.border(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final primary = AppTokens.primary(isDark);
    final onPrimary = AppTokens.onPrimary(isDark);
    final primaryContainer = AppTokens.primaryContainer(isDark);
    final sageInk = AppTokens.sageInk(isDark);
    final error = AppTokens.error(isDark);

    final textTheme = GoogleFonts.dmSansTextTheme(baseText).copyWith(
      displayLarge: AppTokens.display(fontSize: 32, color: textPrimary),
      displayMedium: AppTokens.display(fontSize: 26, color: textPrimary),
      headlineMedium: AppTokens.display(fontSize: 22, color: textPrimary),
      titleLarge: AppTokens.display(fontSize: 20, fontWeight: FontWeight.w500, color: textPrimary),
      titleMedium: GoogleFonts.dmSans(
        textStyle: baseText.titleMedium,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: AppTokens.sansBody(fontSize: 15, color: textPrimary),
      bodyMedium: AppTokens.sansBody(fontSize: 14, color: textPrimary),
      bodySmall: AppTokens.sansBody(fontSize: 12.5, color: textSecondary),
      labelLarge: AppTokens.kicker(fontSize: 11.5, color: textPrimary),
    );

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primaryContainer,
            onPrimaryContainer: sageInk,
            secondary: AppTokens.sandInkDark,
            onSecondary: bg,
            surface: surface,
            onSurface: textPrimary,
            surfaceContainerHighest: surfaceMuted,
            outline: border,
            error: error,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: onPrimary,
            primaryContainer: primaryContainer,
            onPrimaryContainer: sageInk,
            secondary: AppTokens.sandInkLight,
            onSecondary: surface,
            surface: surface,
            onSurface: textPrimary,
            surfaceContainerHighest: surfaceMuted,
            outline: border,
            error: error,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      dividerColor: border,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary, size: 21),
        titleTextStyle: AppTokens.display(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: sageInk, size: 21);
          }
          return IconThemeData(color: textSecondary, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.kicker(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: sageInk,
            );
          }
          return AppTokens.kicker(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.7,
            color: textSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          textStyle: AppTokens.sansBody(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          textStyle: AppTokens.sansBody(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: sageInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          elevation: 0,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryContainer;
            }
            return surfaceMuted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return sageInk;
            }
            return textSecondary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: border, width: 1.0)),
          textStyle: WidgetStateProperty.all(
            AppTokens.sansBody(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppTokens.surfaceWarmDark : AppTokens.textPrimaryLight,
        contentTextStyle: AppTokens.sansBody(
          fontSize: 13.5,
          color: AppTokens.textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),
      textTheme: textTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPackProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Weekly Recipes',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: _buildTheme(isDark: false),
          darkTheme: _buildTheme(isDark: true),
          home: const MainLayout(),
        );
      },
    );
  }
}
