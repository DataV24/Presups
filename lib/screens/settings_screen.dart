import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _usarBiometria = false;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Por defecto desactivado (false) o lo que tenga guardado
      _usarBiometria = prefs.getBool('usar_biometria') ?? false;
    });
  }

  Future<void> _cambiarBiometria(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usar_biometria', valor);
    setState(() {
      _usarBiometria = valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Bloqueo con Huella Digital'),
            subtitle: const Text('Pedir huella al abrir la app'),
            secondary: const Icon(Icons.fingerprint),
            value: _usarBiometria,
            onChanged: _cambiarBiometria,
          ),
          // Aquí podrás agregar más ajustes luego (Moneda, Tema, etc.)
        ],
      ),
    );
  }
}
