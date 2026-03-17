import 'package:flutter/material.dart';
import '../models/gasto.dart';
import 'chart_bar.dart';

class Chart extends StatelessWidget {
  const Chart({
    super.key,
    required this.recentTransactions,
    required this.onCategoryTap,
    this.color = Colors.red, // Color por defecto Rojo (Gastos)
  });

  final List<Gasto> recentTransactions;
  final void Function(Categoria categoria) onCategoryTap;
  final Color color;

  // GENERACIÓN DINÁMICA DE BUCKETS
  List<Bucket> get buckets {
    // 1. Detectamos qué categorías existen en la lista que nos pasaron
    final uniqueCategories = recentTransactions.map((e) => e.categoria).toSet();

    // 2. Creamos un bucket para cada categoría encontrada
    return uniqueCategories
        .map((cat) => Bucket.forCategory(recentTransactions, cat))
        .toList();
  }

  double get maxTotalExpense {
    double maxTotal = 0;
    for (final bucket in buckets) {
      if (bucket.totalExpenses > maxTotal) {
        maxTotal = bucket.totalExpenses;
      }
    }
    return maxTotal;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeBuckets = buckets.where((b) => b.totalExpenses > 0).toList();

    // Ordenamos para que se vea bonito (de mayor a menor monto)
    activeBuckets.sort((a, b) => b.totalExpenses.compareTo(a.totalExpenses));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2), // Fondo degradado del color elegido
            color.withOpacity(0.0),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: activeBuckets.isEmpty
          ? Center(
              child: Text(
                "Sin datos",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in activeBuckets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => onCategoryTap(bucket.category),
                        child: ChartBar(
                          fill: bucket.totalExpenses == 0
                              ? 0
                              : bucket.totalExpenses / maxTotalExpense,
                          icon: categoriaIconos[bucket.category]!,
                          label: bucket.category.name.toUpperCase(),
                          color: color, // Pasamos el color a la barra
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class Bucket {
  final Categoria category;
  final double totalExpenses;

  Bucket({required this.category, required this.totalExpenses});

  Bucket.forCategory(List<Gasto> allExpenses, this.category)
    : totalExpenses = allExpenses
          .where((expense) => expense.categoria == category)
          .fold(0, (sum, item) => sum + item.monto);
}
