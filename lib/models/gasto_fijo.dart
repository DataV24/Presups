import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
};

class GastoFijo {
  final String id;
  final String titulo;
  final double monto;
  final int diaPago;
  bool estaPagado;
  final bool esIngreso;

  GastoFijo({
    required this.id,
    required this.titulo,
    required this.monto,
    required this.diaPago,
    this.estaPagado = false,
    this.esIngreso = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'monto': monto,
      'dia_pago': diaPago,
      'esta_pagado': estaPagado ? 1 : 0,
      'es_ingreso': esIngreso ? 1 : 0,
    };
  }
}
