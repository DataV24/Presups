import 'package:flutter/material.dart';
import '../db/db_helper.dart';
// SOLUCIÓN 1: Usamos 'hide Categoria' para que no choque con la otra importación
import '../models/gasto_fijo.dart' hide Categoria;
import '../models/gasto.dart';

class GastosFijosScreen extends StatefulWidget {
  const GastosFijosScreen({super.key});

  @override
  State<GastosFijosScreen> createState() => _GastosFijosScreenState();
}

class _GastosFijosScreenState extends State<GastosFijosScreen> {
  List<GastoFijo> _gastosFijos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final data = await DBHelper.getGastosFijos();
    setState(() {
      _gastosFijos = data
          .map(
            (item) => GastoFijo(
              id: item['id'],
              titulo: item['titulo'],
              monto: item['monto'],
              diaPago: item['dia_pago'],
              estaPagado: item['esta_pagado'] == 1,
              esIngreso: (item['es_ingreso'] ?? 0) == 1,
            ),
          )
          .toList();
      _isLoading = false;
    });
  }

  void _mostrarFormulario({GastoFijo? gastoEditar}) {
    final tituloController = TextEditingController(
      text: gastoEditar?.titulo ?? '',
    );
    final montoController = TextEditingController(
      text: gastoEditar?.monto.toString() ?? '',
    );
    final diaController = TextEditingController(
      text: gastoEditar?.diaPago.toString() ?? '',
    );
    bool esIngreso = gastoEditar?.esIngreso ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              gastoEditar == null ? 'Nuevo Recurrente' : 'Editar Recurrente',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        esIngreso ? 'Ingreso' : 'Gasto',
                        style: TextStyle(
                          color: esIngreso ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: esIngreso,
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: (val) =>
                            setStateDialog(() => esIngreso = val),
                      ),
                    ],
                  ),
                  TextField(
                    controller: tituloController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: montoController,
                    decoration: const InputDecoration(labelText: 'Monto (Q)'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextField(
                    controller: diaController,
                    decoration: const InputDecoration(labelText: 'Día del mes'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tituloController.text.isEmpty ||
                      montoController.text.isEmpty) {
                    return;
                  }

                  // --- AQUÍ ESTÁ LA SOLUCIÓN AL ERROR 58,3 ---
                  // 1. Reemplazamos coma por punto
                  String montoString = montoController.text.replaceAll(
                    ',',
                    '.',
                  );
                  // 2. Usamos tryParse para que no explote la app
                  double? montoFinal = double.tryParse(montoString);

                  if (montoFinal == null) {
                    // Si el número no es válido, no hacemos nada
                    return;
                  }

                  final nuevoGasto = GastoFijo(
                    id: gastoEditar?.id ?? DateTime.now().toString(),
                    titulo: tituloController.text,
                    monto: montoFinal, // ¡Usamos el monto limpio!
                    diaPago: int.tryParse(diaController.text) ?? 1,
                    esIngreso: esIngreso,
                    estaPagado: gastoEditar?.estaPagado ?? false,
                  );

                  await DBHelper.insertGastoFijo(nuevoGasto);

                  // Actualizar Billetera si ya estaba pagado
                  if (nuevoGasto.estaPagado) {
                    final now = DateTime.now();
                    final String idTransaccion =
                        "${nuevoGasto.id}_${now.month}_${now.year}";

                    final transaccionActualizada = Gasto(
                      id: idTransaccion,
                      titulo: "${nuevoGasto.titulo} (Fijo)",
                      monto: montoFinal,
                      fecha: now,
                      // Usamos Categoria.salario o Categoria.otros para evitar conflictos
                      categoria: nuevoGasto.esIngreso
                          ? Categoria.salario
                          : Categoria.fijos,
                      esIngreso: nuevoGasto.esIngreso,
                      esFijo: true,
                    );
                    await DBHelper.insertGasto(transaccionActualizada);
                  }

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _cargarDatos();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _togglePago(GastoFijo fijo) async {
    bool nuevoEstado = !fijo.estaPagado;
    await DBHelper.toggleGastoFijo(fijo.id, nuevoEstado);

    final now = DateTime.now();
    final String idTransaccion = "${fijo.id}_${now.month}_${now.year}";

    if (nuevoEstado) {
      final nuevaTransaccion = Gasto(
        id: idTransaccion,
        titulo: "${fijo.titulo} (Fijo)",
        monto: fijo.monto,
        fecha: now,
        categoria: fijo.esIngreso ? Categoria.salario : Categoria.fijos,
        esIngreso: fijo.esIngreso,
        esFijo: true,
      );
      await DBHelper.insertGasto(nuevaTransaccion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fijo.esIngreso ? '¡Ingreso sumado!' : '¡Pago registrado!',
            ),
            backgroundColor: fijo.esIngreso ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      await DBHelper.deleteGasto(idTransaccion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado de la billetera'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
    _cargarDatos();
  }

  void _eliminarGasto(String id) async {
    await DBHelper.deleteGastoFijo(id);
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Mensual')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _gastosFijos.length,
              itemBuilder: (ctx, index) {
                final item = _gastosFijos[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onDismissed: (_) => _eliminarGasto(item.id),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    surfaceTintColor: Colors.white,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        // SOLUCIÓN 2: Usamos withValues en lugar de withOpacity
                        color: item.esIngreso
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.red.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      trailing: Checkbox(
                        value: item.estaPagado,
                        activeColor: item.esIngreso ? Colors.green : Colors.red,
                        onChanged: (_) => _togglePago(item),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: item.esIngreso
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          item.esIngreso
                              ? Icons.attach_money
                              : Icons.calendar_today,
                          color: item.esIngreso
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      title: Text(
                        item.titulo,
                        style: TextStyle(
                          decoration: item.estaPagado
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.estaPagado ? Colors.grey : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        item.esIngreso
                            ? 'Día cobro: ${item.diaPago}'
                            : 'Vence día: ${item.diaPago}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      onTap: () => _mostrarFormulario(gastoEditar: item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
