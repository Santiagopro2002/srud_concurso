import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/clients_models.dart';
import '../../repositories/clients_repository.dart';
import '../../settings/database_connection.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ClientsRepository clientsRepo = ClientsRepository();
  final database = DatabaseConnection();

  List<ClientsModels> clientes = [];
  int? clientIdSeleccionado;

  double ingresos = 0;
  double gastos = 0;
  double balance = 0;

  bool cargandoClientes = true;
  bool cargandoDatos = false;
  bool mostrar = false;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    setState(() => cargandoClientes = true);
    try {
      clientes = await clientsRepo.getAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando clientes: $e")));
    } finally {
      if (mounted) setState(() => cargandoClientes = false);
    }
  }

  Future<void> buscarResumen() async {
    if (clientIdSeleccionado == null) return;

    setState(() {
      cargandoDatos = true;
      mostrar = false;
    });

    try {
      final db = await database.db;

      final ingresosResult = await db.rawQuery(
        '''
        SELECT SUM(monto) as total
        FROM movimientos
        WHERE client_id = ? AND tipo = 'ingreso'
        ''',
        [clientIdSeleccionado],
      );

      final gastosResult = await db.rawQuery(
        '''
        SELECT SUM(monto) as total
        FROM movimientos
        WHERE client_id = ? AND tipo = 'gasto'
        ''',
        [clientIdSeleccionado],
      );

      final ing = (ingresosResult.first['total'] as num?)?.toDouble() ?? 0;
      final gas = (gastosResult.first['total'] as num?)?.toDouble() ?? 0;

      setState(() {
        ingresos = ing;
        gastos = gas;
        balance = ing - gas;
        mostrar = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error calculando resumen: $e")));
    } finally {
      if (mounted) setState(() => cargandoDatos = false);
    }
  }

  void limpiar() {
    setState(() {
      clientIdSeleccionado = null;
      ingresos = 0;
      gastos = 0;
      balance = 0;
      mostrar = false;
    });
  }

  String _money(double v) => "\$${v.toStringAsFixed(2)}";

  Color _balanceColor() => balance >= 0 ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    final selectedName = clientes
        .where((c) => c.id == clientIdSeleccionado)
        .map((c) => c.nombre)
        .toList();
    final nombreCliente = selectedName.isEmpty ? "—" : selectedName.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        actions: [
          IconButton(
            tooltip: "Recargar clientes",
            onPressed: cargarClientes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header pro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Balance por cliente",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Selecciona un cliente y revisa su resumen financiero.",
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Selector cliente
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cliente",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    cargandoClientes
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: clientIdSeleccionado,
                            items: clientes.map((cliente) {
                              return DropdownMenuItem<int>(
                                value: cliente.id,
                                child: Text(
                                  cliente.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => clientIdSeleccionado = value);
                            },
                            decoration: InputDecoration(
                              hintText: "Seleccione un ciudadano",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                clientIdSeleccionado == null || cargandoDatos
                                ? null
                                : buscarResumen,
                            icon: const Icon(Icons.search),
                            label: Text(
                              cargandoDatos ? "Calculando..." : "Buscar",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: limpiar,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text("Limpiar"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF111827),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: Colors.black26),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Seleccionado: $nombreCliente",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (mostrar) ...[
                // Tarjetas resumen
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 560;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 2.2 : 1.8,
                      children: [
                        _KpiCard(
                          title: "Ingresos",
                          value: _money(ingresos),
                          icon: Icons.arrow_circle_up,
                          iconColor: Colors.green,
                        ),
                        _KpiCard(
                          title: "Gastos",
                          value: _money(gastos),
                          icon: Icons.arrow_circle_down,
                          iconColor: Colors.red,
                        ),
                        _KpiCard(
                          title: "Balance",
                          value: _money(balance),
                          icon: Icons.account_balance_wallet,
                          iconColor: _balanceColor(),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Gráfica
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Resumen gráfico",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Comparación entre ingresos, gastos y balance.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _maxY(ingresos, gastos, balance),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    // solo algunos ticks
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final v = value.toInt();
                                    String t = "";
                                    if (v == 0) t = "Ingresos";
                                    if (v == 1) t = "Gastos";
                                    if (v == 2) t = "Balance";
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        t,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: ingresos,
                                    width: 20,
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: gastos,
                                    width: 20,
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: balance.abs(), // para que sea visible
                                    width: 20,
                                    color: _balanceColor(),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _LegendDot(color: Colors.green, label: "Ingresos"),
                          const SizedBox(width: 10),
                          _LegendDot(color: Colors.red, label: "Gastos"),
                          const SizedBox(width: 10),
                          _LegendDot(color: _balanceColor(), label: "Balance"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _maxY(double a, double b, double c) {
    // Como balance puede ser negativo, usamos abs para escala
    final maxValue = [a, b, c.abs()].reduce((x, y) => x > y ? x : y);
    if (maxValue <= 0) return 10;
    return maxValue * 1.25; // margen arriba
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
