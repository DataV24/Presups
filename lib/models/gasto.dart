import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

final formatter = DateFormat.yMd();

const uuid = Uuid();

enum Categoria {
  comida,
  transporte,
  ocio,
  trabajo,
  vivienda,
  salud,
  otros,
  salario,
  negocio,
  regalo,
  fijos, // <--- NUEVA CATEGORÍA OFICIAL
}

// Iconos para cada categoría
const categoriaIconos = {
  Categoria.comida: Icons.lunch_dining,
  Categoria.transporte: Icons.flight_takeoff,
  Categoria.ocio: Icons.movie,
  Categoria.trabajo: Icons.work,
  Categoria.vivienda: Icons.home,
  Categoria.salud: Icons.local_hospital,
  Categoria.otros: Icons.error,
  Categoria.salario: Icons.attach_money,
  Categoria.negocio: Icons.store,
  Categoria.regalo: Icons.card_giftcard,
  Categoria.fijos: Icons.push_pin, // <--- ICONO PARA FIJOS
};

class Gasto {
  final String id;
  final String titulo;
  final double monto;
  final DateTime fecha;
  final Categoria categoria;
  final bool esIngreso;
  final bool esFijo;

  Gasto({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.fecha,
    required this.categoria,
    required this.esIngreso,
    this.esFijo = false,
  });

  String get fechaFormateada {
    return formatter.format(fecha);
  }
}
