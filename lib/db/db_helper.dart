import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

// TUS MODELOS
import '../models/gasto.dart';
import '../models/gasto_fijo.dart';

class DBHelper {
  static Future<Database> _getDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      // CAMBIO CLAVE: Usamos 'gastos_v2.db' para empezar de cero absoluto
      path.join(dbPath, 'gastos_v2.db'),
      onCreate: (db, version) async {
        // 1. Tabla de Gastos Normales (Billetera)
        await db.execute(
          'CREATE TABLE user_expenses(id TEXT PRIMARY KEY, titulo TEXT, monto REAL, fecha TEXT, categoria TEXT, esIngreso INTEGER, esFijo INTEGER)',
        );

        // 2. Tabla de Gastos Fijos (Control Mensual)
        await db.execute(
          'CREATE TABLE gastos_fijos(id TEXT PRIMARY KEY, titulo TEXT, monto REAL, dia_pago INTEGER, esta_pagado INTEGER, es_ingreso INTEGER)',
        );
      },
      version: 1, // Reiniciamos la versión a 1 porque es una DB nueva
    );
  }

  // ==========================================
  //      CRUD DE GASTOS NORMALES (Billetera)
  // ==========================================

  static Future<void> insertGasto(Gasto gasto) async {
    final db = await _getDatabase();
    await db.insert('user_expenses', {
      'id': gasto.id,
      'titulo': gasto.titulo,
      'monto': gasto.monto,
      'fecha': gasto.fecha.toIso8601String(),
      'categoria': gasto.categoria.toString(),
      'esIngreso': gasto.esIngreso ? 1 : 0,
      'esFijo': gasto.esFijo ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getGastos() async {
    final db = await _getDatabase();
    return db.query('user_expenses', orderBy: "fecha DESC");
  }

  static Future<void> deleteGasto(String id) async {
    final db = await _getDatabase();
    await db.delete('user_expenses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateGasto(Gasto gasto) async {
    final db = await _getDatabase();
    await db.update(
      'user_expenses',
      {
        'titulo': gasto.titulo,
        'monto': gasto.monto,
        'fecha': gasto.fecha.toIso8601String(),
        'categoria': gasto.categoria.toString(),
        'esIngreso': gasto.esIngreso ? 1 : 0,
        'esFijo': gasto.esFijo ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  // ==========================================
  //      CRUD DE GASTOS FIJOS (Recurrentes)
  // ==========================================

  static Future<void> insertGastoFijo(GastoFijo gasto) async {
    final db = await _getDatabase();
    await db.insert(
      'gastos_fijos',
      gasto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getGastosFijos() async {
    final db = await _getDatabase();
    return db.query('gastos_fijos', orderBy: "dia_pago ASC");
  }

  static Future<void> deleteGastoFijo(String id) async {
    final db = await _getDatabase();
    await db.delete('gastos_fijos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleGastoFijo(String id, bool estaPagado) async {
    final db = await _getDatabase();
    await db.update(
      'gastos_fijos',
      {'esta_pagado': estaPagado ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
