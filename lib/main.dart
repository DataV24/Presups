import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // INICIALIZAMOS (Esto ya no dará error con la librería v18)
  await NotificationService.init();
  await NotificationService.scheduleDailyNotifications();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const GastosApp());
}

class GastosApp extends StatefulWidget {
  const GastosApp({super.key});

  @override
  State<GastosApp> createState() => _GastosAppState();
}

class _GastosAppState extends State<GastosApp> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _canCheckBiometrics = false;
  bool _esPrimeraVez = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _iniciarApp();
  }

  Future<void> _iniciarApp() async {
    final prefs = await SharedPreferences.getInstance();
    bool visto = prefs.getBool('visto_bienvenida_v2') ?? false;
    bool usarBiometria = prefs.getBool('usar_biometria') ?? false;

    if (!mounted) return;

    if (!visto) {
      setState(() {
        _esPrimeraVez = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _esPrimeraVez = false;
      });

      if (usarBiometria) {
        await _checkBiometrics();
      } else {
        setState(() => _isAuthenticated = true);
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!mounted) return;

      setState(() => _canCheckBiometrics = canCheck && isDeviceSupported);

      if (_canCheckBiometrics) {
        _authenticate();
      } else {
        setState(() => _isAuthenticated = true);
      }
    } catch (e) {
      debugPrint("Error biometría: $e");
      if (mounted) setState(() => _isAuthenticated = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Por favor autentícate para ver tus gastos 🔐',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (!mounted) return;
      setState(() => _isAuthenticated = didAuthenticate);
    } catch (e) {
      debugPrint("Error auth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 26, 99, 29),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 12, 48, 13),
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Color.fromARGB(255, 30, 30, 30),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color.fromARGB(255, 30, 30, 30),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Gastos',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _esPrimeraVez
          ? const WelcomeScreen()
          : _isAuthenticated
          ? const HomeScreen()
          : Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 100, color: Colors.green),
                    const SizedBox(height: 20),
                    const Text(
                      "Acceso Restringido",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text("Desbloquear"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
