import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_helper.dart';
import '../models/gasto_fijo.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final List<GastoFijo> _gastosTemporales = [];

  void _agregarGasto() {
    final tituloController = TextEditingController();
    final montoController = TextEditingController();
    final diaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Gasto Fijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Nombre (Ej: Internet)',
              ),
            ),
            TextField(
              controller: montoController,
              decoration: const InputDecoration(labelText: 'Monto (Q)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: diaController,
              decoration: const InputDecoration(
                labelText: 'Día de pago (Ej: 15)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // CORRECCIÓN 1: Agregamos las llaves {}
              if (tituloController.text.isEmpty ||
                  montoController.text.isEmpty) {
                return;
              }

              final nuevoGasto = GastoFijo(
                id: DateTime.now().toString(),
                titulo: tituloController.text,
                monto: double.parse(montoController.text),
                diaPago: int.tryParse(diaController.text) ?? 1,
              );

              // 1. Guardar en Base de Datos de una vez
              await DBHelper.insertGastoFijo(nuevoGasto);

              // 2. Actualizar la lista visual
              setState(() {
                _gastosTemporales.add(nuevoGasto);
              });

              // CORRECCIÓN 2: Verificamos si el contexto del diálogo sigue vivo
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _terminarConfiguracion() async {
    // 1. Guardar en la memoria que ya vimos la bienvenida
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('visto_bienvenida_v2', true);

    // CORRECCIÓN 3: Agregamos llaves {} al check de mounted
    if (!mounted) {
      return;
    }

    // 2. Ir al Home y no dejar volver atrás
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (ctx) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50, // Mantenemos tu diseño suave
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.waving_hand, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Hola! Bienvenido a tu Billetera.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Para empezar con el pie derecho, registremos tus gastos fijos (Renta, Luz, Internet, etc).',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // LISTA DE LO QUE VAS AGREGANDO
              Expanded(
                child: _gastosTemporales.isEmpty
                    ? Center(
                        child: Text(
                          'No has agregado nada aún.',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _gastosTemporales.length,
                        itemBuilder: (ctx, index) {
                          final g = _gastosTemporales[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.check, size: 15),
                              ),
                              title: Text(g.titulo),
                              trailing: Text('Q${g.monto.toStringAsFixed(0)}'),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // BOTONES DE ACCIÓN
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _agregarGasto,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar un Gasto Fijo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _terminarConfiguracion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    '¡Todo Listo! Ir a la App',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
