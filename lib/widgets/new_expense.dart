import 'package:flutter/material.dart';
import '../models/gasto.dart';

class NewExpense extends StatefulWidget {
  final void Function(Gasto gasto) onSaveExpense;
  final Gasto? gastoExistente;

  const NewExpense({
    super.key,
    required this.onSaveExpense,
    this.gastoExistente,
  });

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  Categoria _selectedCategory = Categoria.comida;
  bool _esIngreso = false;

  // Listas de categorías según el tipo
  final List<Categoria> _exclusivoIngresos = [
    Categoria.salario,
    Categoria.negocio,
    Categoria.regalo,
  ];

  List<Categoria> get _listaParaIngresos => [
    Categoria.salario,
    Categoria.negocio,
    Categoria.regalo,
    Categoria.otros,
  ];

  List<Categoria> get _listaParaGastos => Categoria.values
      .where(
        (cat) => !_exclusivoIngresos.contains(cat) && cat != Categoria.fijos,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    // Ponemos la fecha de hoy por defecto para evitar que salga "null" o barra amarilla
    _selectedDate = DateTime.now();

    if (widget.gastoExistente != null) {
      final g = widget.gastoExistente!;
      _titleController.text = g.titulo;
      _amountController.text = g.monto.toString();
      _selectedDate = g.fecha;
      _selectedCategory = g.categoria;
      _esIngreso = g.esIngreso;
    }
  }

  void _submitExpenseData() {
    // --- CORRECCIÓN IMPORTANTE PARA SAMSUNG ---
    // Agregamos el .replaceAll(',', '.') para que no falle en tu celular
    final montoLimpio = _amountController.text.replaceAll(',', '.');
    final enteredAmount = double.tryParse(montoLimpio);

    final amountIsInvalid = enteredAmount == null || enteredAmount <= 0;

    if (_titleController.text.trim().isEmpty ||
        amountIsInvalid ||
        _selectedDate == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Datos inválidos'),
          content: const Text(
            'Por favor revisa el título, el monto y la fecha.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
      return;
    }

    final gastoFinal = Gasto(
      id: widget.gastoExistente?.id ?? DateTime.now().toString(),
      titulo: _titleController.text,
      monto: enteredAmount, // Usamos el monto limpio
      fecha: _selectedDate!,
      categoria: _selectedCategory,
      esIngreso: _esIngreso,
      esFijo: widget.gastoExistente?.esFijo ?? false,
    );

    widget.onSaveExpense(gastoFinal);
    Navigator.pop(context);
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.gastoExistente != null;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        // Agregamos padding inferior para el teclado
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esEdicion
                  ? (_esIngreso ? "Editar Ingreso" : "Editar Gasto")
                  : "Nuevo Movimiento",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // SWITCH CENTRADO (Tu diseño original)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Gasto",
                  style: TextStyle(
                    color: _esIngreso ? Colors.grey : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _esIngreso,
                  activeTrackColor: Colors.green.shade200,
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.shade200,
                  onChanged: (val) {
                    setState(() {
                      _esIngreso = val;
                      _selectedCategory = _esIngreso
                          ? Categoria.salario
                          : Categoria.comida;
                    });
                  },
                ),
                Text(
                  "Ingreso",
                  style: TextStyle(
                    color: _esIngreso ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                label: Text('Título'),
                prefixIcon: Icon(Icons.abc),
              ),
            ),

            Row(
              children: [
                // MONTO
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    // Teclado con decimales
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'Q ',
                      label: Text('Monto'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // CATEGORÍA (Con tu diseño de InputDecorator)
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Categoria>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items:
                            (_esIngreso ? _listaParaIngresos : _listaParaGastos)
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category.name.toUpperCase()),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // FECHA
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Hoy'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      IconButton(
                        onPressed: _presentDatePicker,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // BOTONES
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitExpenseData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _esIngreso
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    foregroundColor: _esIngreso
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                    elevation: 0,
                  ),
                  child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
