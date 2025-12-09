import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_manager/providers/transaction_provider.dart';
import 'package:expense_manager/providers/theme_provider.dart';
import 'package:expense_manager/screens/home_page.dart';
import 'package:expense_manager/db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize database (safe to await)
  await DatabaseHelper.instance.initDB();

  // create ThemeProvider synchronously (do NOT call SharedPreferences here)
  final themeProvider = ThemeProvider();

  // Start the app immediately
  runApp(ExpenseManagerApp(themeProvider: themeProvider));
}

class ExpenseManagerApp extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ExpenseManagerApp({required this.themeProvider, super.key});

  @override
  State<ExpenseManagerApp> createState() => _ExpenseManagerAppState();
}

class _ExpenseManagerAppState extends State<ExpenseManagerApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Load saved theme preference after engine is ready to avoid platform-channel errors.
    widget.themeProvider.loadFromPrefs().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Palette derived from your reference image:
    // Dark mode (left): deep maroon/plum tones (accent colors kept)
    const darkAccent1 = Color(0xFFB53A3A); // primary muted red accent for CTAs
    const darkAccent2 = Color(0xFF9E3333);
    const darkAccent3 = Color(0xFF7F2A2A);
    const darkAccent4 = Color(0xFF5C1E1E);
    // Use a dark grey for the scaffold background as requested
    const darkSurface = Color(0xFF121212); // <-- changed to dark grey

    // Light mode (right): warm peach + dusty blue slate
    const lightAccent1 = Color(0xFFF0B86D); // warm peach
    const lightAccent2 = Color(0xFFD8737F); // dusty rose
    const lightAccent3 = Color(0xFFA8B6C2); // muted blue-gray
    const lightAccent4 = Color(0xFFB6D7D9); // pale teal
    const lightSurface = Color(0xFF475C7A); // slate (good for primary elements)

    final lightColorScheme = ColorScheme.fromSwatch(
      primarySwatch: createMaterialColor(lightSurface),
      brightness: Brightness.light,
    ).copyWith(secondary: lightAccent1);

    final darkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: createMaterialColor(darkSurface),
      brightness: Brightness.dark,
    ).copyWith(secondary: darkAccent1);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: lightSurface,
      colorScheme: lightColorScheme,
      // slightly darker off-white to reduce glare
      scaffoldBackgroundColor: const Color(0xFFF2EFEA),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent1,
          foregroundColor: Colors.white,
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      // toggles use the secondary (accent) color
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => lightAccent1),
        trackColor: WidgetStateProperty.resolveWith((_) => lightAccent1.withOpacity(0.36)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((_) => lightAccent1),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((_) => lightAccent1),
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkSurface,
      colorScheme: darkColorScheme,
      // apply the requested dark grey scaffold background
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      // card surfaces slightly lighter than scaffold for subtle contrast
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1B1B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent1,
          foregroundColor: Colors.white,
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((_) => darkAccent1),
        trackColor: WidgetStateProperty.resolveWith((_) => darkAccent1.withOpacity(0.36)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((_) => darkAccent1),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((_) => darkAccent1),
      ),
      useMaterial3: true,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadTransactions()),
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Manager',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            // show a tiny splash while theme loads to avoid a flash
            home: _ready ? const HomePage() : const _LoadingSplash(),
          );
        },
      ),
    );
  }
}

class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
      ),
    );
  }
}

/// Helper to create MaterialColor from single Color.
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) strengths.add(0.1 * i);
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}