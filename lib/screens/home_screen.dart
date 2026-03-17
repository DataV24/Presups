import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart'; // <--- IMPORTANTE
import '../models/gasto.dart';
import '../widgets/new_expense.dart';
import '../widgets/chart.dart';
import '../db/db_helper.dart';
import 'gastos_fijos_screen.dart';
import 'settings_screen.dart';
import 'calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Gasto> _todasLasTransacciones = [];
  List<Gasto> _transaccionesDelMes = [];

  bool _isLoading = true;
  int _paginaActual = 0;
  DateTime _fechaSeleccionada = DateTime.now();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarGastos() async {
    final data = await DBHelper.getGastos();
    setState(() {
      _todasLasTransacciones = data
          .map(
            (item) => Gasto(
              id: item['id'],
              titulo: item['titulo'],
              monto: item['monto'],
              fecha: DateTime.parse(item['fecha']),
              categoria: Categoria.values.firstWhere(
                (c) => c.toString() == item['categoria'],
                orElse: () => Categoria.otros,
              ),
              esIngreso: (item['esIngreso'] ?? 0) == 1,
              esFijo: (item['esFijo'] ?? 0) == 1,
            ),
          )
          .toList();

      _aplicarFiltros();
      _isLoading = false;
    });
  }

  void _aplicarFiltros() {
    _transaccionesDelMes = _todasLasTransacciones.where((tx) {
      return tx.fecha.month == _fechaSeleccionada.month &&
          tx.fecha.year == _fechaSeleccionada.year;
    }).toList();

    _transaccionesDelMes.sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  bool get _esMesActual {
    final now = DateTime.now();
    return _fechaSeleccionada.year == now.year &&
        _fechaSeleccionada.month == now.month;
  }

  void _cambiarMes(int meses) {
    if (meses > 0 && _esMesActual) return;
    setState(() {
      _fechaSeleccionada = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month + meses,
        1,
      );
      _aplicarFiltros();
    });
  }

  double get _totalIngresos => _transaccionesDelMes
      .where((t) => t.esIngreso)
      .fold(0.0, (sum, item) => sum + item.monto);
  double get _totalGastos => _transaccionesDelMes
      .where((t) => !t.esIngreso)
      .fold(0.0, (sum, item) => sum + item.monto);
  double get _balanceTotal => _totalIngresos - _totalGastos;

  Future<void> _exportarCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["Fecha", "Título", "Monto", "Categoría", "Tipo", "Es Fijo"]);
    for (var t in _todasLasTransacciones) {
      rows.add([
        "${t.fecha.day}/${t.fecha.month}/${t.fecha.year}",
        t.titulo,
        t.monto,
        t.categoria.name.toUpperCase(),
        t.esIngreso ? "Ingreso" : "Gasto",
        t.esFijo ? "Sí" : "No",
      ]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/reporte_gastos.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: '📊 Mi reporte de gastos');
  }

  void _mostrarFormulario({Gasto? gastoParaEditar}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: NewExpense(
            gastoExistente: gastoParaEditar,
            onSaveExpense: (gasto) async {
              if (gastoParaEditar == null) {
                await DBHelper.insertGasto(gasto);
              } else {
                await DBHelper.updateGasto(gasto);
              }
              await _cargarGastos();
            },
          ),
        ),
      ),
    );
  }

  void _confirmarBorrado(Gasto gasto) {
    if (gasto.esFijo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Edita los gastos fijos en "Control Mensual"'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text('Se borrará "${gasto.titulo}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DBHelper.deleteGasto(gasto.id);
              _cargarGastos();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- DETALLE CATEGORÍA ---
  void _mostrarDetalleCategoria(
    Categoria categoria,
    List<Gasto> listaCompleta,
  ) {
    final gastosDeCategoria = listaCompleta
        .where((g) => g.categoria == categoria)
        .toList();
    final esIngreso =
        gastosDeCategoria.isNotEmpty && gastosDeCategoria.first.esIngreso;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Detalle: ${categoria.name.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: esIngreso ? Colors.green : Colors.red,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: gastosDeCategoria.isEmpty
                      ? const Center(child: Text("No hay registros."))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: gastosDeCategoria.length,
                          itemBuilder: (ctx, index) {
                            final g = gastosDeCategoria[index];
                            return ListTile(
                              leading: Icon(
                                categoriaIconos[categoria],
                                color: g.esIngreso ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                g.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(g.fecha),
                              ),
                              trailing: Text(
                                "Q ${g.monto.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: g.esIngreso
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onPageChanged(int index) {
    setState(() => _paginaActual = index);
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    String tituloMes = DateFormat('MMMM y', 'es').format(_fechaSeleccionada);
    tituloMes = tituloMes[0].toUpperCase() + tituloMes.substring(1);

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 1. PESTAÑA BILLETERA
    Widget contenidoBilletera = Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => _cambiarMes(-1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Text(
                  tituloMes,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: _esMesActual ? Colors.grey.shade800 : Colors.white,
                ),
                onPressed: _esMesActual ? null : () => _cambiarMes(1),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _balanceTotal >= 0
                    ? Colors.green.shade800
                    : Colors.red.shade900,
                _balanceTotal >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Saldo en $tituloMes",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Q ${_balanceTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Ingresos",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Q ${_totalIngresos.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "Gastos",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Q ${_totalGastos.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _transaccionesDelMes.isEmpty
              ? Center(
                  child: Text(
                    "Sin movimientos en $tituloMes",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: _transaccionesDelMes.length,
                  itemBuilder: (ctx, index) {
                    final tr = _transaccionesDelMes[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (tr.esFijo) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🔒 Gasto fijo. Edítalo en "Control Mensual"',
                                ),
                              ),
                            );
                            return;
                          }
                          _mostrarFormulario(gastoParaEditar: tr);
                        },
                        onLongPress: () => _confirmarBorrado(tr),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tr.esIngreso
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              tr.esFijo
                                  ? Icons.lock
                                  : (tr.esIngreso
                                        ? Icons.attach_money
                                        : categoriaIconos[tr.categoria]),
                              color: tr.esIngreso ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            tr.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${tr.fecha.day}/${tr.fecha.month} - ${tr.categoria.name.toUpperCase()}',
                          ),
                          trailing: Text(
                            '${tr.esIngreso ? "+" : "-"} Q${tr.monto.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tr.esIngreso ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    // 2. PESTAÑA ANÁLISIS (DOBLE GRÁFICA)
    final soloIngresos = _transaccionesDelMes
        .where((t) => t.esIngreso)
        .toList();
    final soloGastos = _transaccionesDelMes.where((t) => !t.esIngreso).toList();

    Widget contenidoEstadisticas = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN INGRESOS
          const Text(
            "Ingresos del Mes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Chart(
            recentTransactions: soloIngresos,
            color: Colors.green, // <--- GRÁFICA VERDE
            onCategoryTap: (cat) => _mostrarDetalleCategoria(cat, soloIngresos),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // SECCIÓN GASTOS
          const Text(
            "Gastos del Mes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          Chart(
            recentTransactions: soloGastos,
            color: Colors.red, // <--- GRÁFICA ROJA
            onCategoryTap: (cat) => _mostrarDetalleCategoria(cat, soloGastos),
          ),

          if (_transaccionesDelMes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: Text(
                  "No hay datos para analizar",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        actions: [
          // BOTÓN DE PRUEBA DE NOTIFICACIÓN
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.yellow),
            onPressed: () async {
              // 1. Mostrar mensaje visual
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🔔 Espera 10 segundos... (Sal de la app si quieres)',
                  ),
                ),
              );
              // 2. Programar la notificación
              // Importa NotificationService arriba si no sale automático
              await NotificationService.programarParaDentroDe10Segundos();
            },
          ),
          IconButton(
            onPressed: _exportarCSV,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Backup',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallet, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Menú Principal',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Gastos Fijos / Pagos'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const GastosFijosScreen(),
                  ),
                );
                _cargarGastos();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Calculadora %'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const CalculatorScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [contenidoBilletera, contenidoEstadisticas],
      ),
      floatingActionButton: _paginaActual == 0
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaActual,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Billetera',
          ),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Análisis'),
        ],
      ),
    );
  }
}
