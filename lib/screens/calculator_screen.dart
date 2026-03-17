import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _porcentajeController = TextEditingController();

  double _resultadoMonto = 0.0;
  double _resultadoSuma = 0.0;
  double _resultadoResta = 0.0;

  void _calcular() {
    double monto = double.tryParse(_montoController.text) ?? 0;
    double porc = double.tryParse(_porcentajeController.text) ?? 0;

    setState(() {
      _resultadoMonto = (monto * porc) / 100;
      _resultadoSuma = monto + _resultadoMonto;
      _resultadoResta = monto - _resultadoMonto;
    });
  }

  void _setPorcentaje(String valor) {
    _porcentajeController.text = valor;
    _calcular();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Esto hace que el teclado se oculte al tocar fuera de los campos
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // Forzamos a que la pantalla se ajuste al teclado
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text("Calculadora de %")),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              children: [
                // TARJETA DE RESULTADOS
                Card(
                  elevation: 4,
                  color: const Color(0xFF303030),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "El porcentaje equivale a:",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Q ${_resultadoMonto.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Total (+)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "Q ${_resultadoSuma.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Total (-)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "Q ${_resultadoResta.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // CAMPOS DE TEXTO
                TextField(
                  controller: _montoController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: "Monto Original (Q)",
                    border: OutlineInputBorder(),
                    // Cambiamos el icono por el texto 'Q' para que sea consistente
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      child: Text(
                        'Q',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) => _calcular(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _porcentajeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: "Porcentaje (%)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  onChanged: (_) => _calcular(),
                ),
                const SizedBox(height: 30),

                // BOTONES RÁPIDOS
                const Text(
                  "Porcentajes Comunes:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _botonChip("5%"),
                    _botonChip("10%"),
                    _botonChip("12% (IVA)", valor: "12"),
                    _botonChip("15%"),
                    _botonChip("25%"),
                    _botonChip("50%"),
                  ],
                ),
                // Espacio extra al final para que el teclado no tape el último botón al scrollear
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonChip(String label, {String? valor}) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.green.shade900,
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide.none,
      onPressed: () {
        _setPorcentaje(valor ?? label.replaceAll('%', ''));
        FocusScope.of(
          context,
        ).unfocus(); // Cerramos teclado al elegir porcentaje
      },
    );
  }
}
