import 'package:flutter/material.dart';

import '../../models/movimientos_models.dart';
import '../../models/clients_models.dart';
import '../../repositories/movimientos_repository.dart';
import '../../repositories/clients_repository.dart';
import '../../settings/database_connection.dart';

class MovimientosFormScreen extends StatefulWidget {
  const MovimientosFormScreen({super.key});

  @override
  State<MovimientosFormScreen> createState() => _MovimientosFormScreenState();
}

class _MovimientosFormScreenState extends State<MovimientosFormScreen> {
  final formKey = GlobalKey<FormState>();

  // Repos / DB
  final ClientsRepository clientsRepo = ClientsRepository();
  final MovimientosRepository movimientosRepo = MovimientosRepository();
  final DatabaseConnection database = DatabaseConnection();

  // Datos
  List<ClientsModels> clientes = [];
  int? clientIdSeleccionado;

  // Modo edición
  MovimientosModels? editingMov;

  // Campos
  String? tipoSeleccionado; // ingreso | gasto
  final montoController = TextEditingController();
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  // Categorías en lista (puedes ampliar)
  final List<String> categorias = const [
    "Alimentación",
    "Transporte",
    "Salud",
    "Educación",
    "Servicios básicos",
    "Arriendo",
    "Entretenimiento",
    "Ropa",
    "Deudas",
    "Ahorro",
    "Otros",
  ];
  String? categoriaSeleccionada;

  // Fecha
  DateTime? fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    try {
      clientes = await clientsRepo.getAll();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando clientes: $e")));
    }
  }

  // Captura argumentos (para editar) sin romper initState
  void _leerArgumentosSiExisten() {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is MovimientosModels && editingMov == null) {
      editingMov = args;

      // precargar
      clientIdSeleccionado = editingMov!.clientId;
      tipoSeleccionado = editingMov!.tipo.toLowerCase().trim();
      categoriaSeleccionada = editingMov!.categoria;
      descripcionController.text = editingMov!.descripcion;
      montoController.text = editingMov!.monto.toString();

      // fecha
      final parsed = DateTime.tryParse(editingMov!.fecha);
      if (parsed != null) {
        fechaSeleccionada = parsed;
        fechaController.text = _formatDate(parsed);
      } else {
        fechaController.text = editingMov!.fecha;
      }
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

  int get currentYear => DateTime.now().year; // en tu caso 2026
  DateTime get today => DateTime.now();

  Future<void> pickFecha() async {
    // Reglas: solo año actual y no fecha futura
    final firstDate = DateTime(currentYear, 1, 1);
    final lastDate = DateTime(today.year, today.month, today.day);

    final initial =
        fechaSeleccionada ??
        (today.year == currentYear ? today : DateTime(currentYear, 1, 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: "Seleccione una fecha (solo $currentYear y no futura)",
    );

    if (picked == null) return;

    setState(() {
      fechaSeleccionada = picked;
      fechaController.text = _formatDate(picked);
    });
  }

  Future<String?> elegirCategoriaConBusqueda() async {
    final controller = TextEditingController();
    List<String> filtradas = List.from(categorias);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx2, setModalState) {
                void filtrar(String q) {
                  final query = q.toLowerCase().trim();
                  setModalState(() {
                    filtradas = categorias
                        .where((c) => c.toLowerCase().contains(query))
                        .toList();
                  });
                }

                return SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.75,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Selecciona una categoría",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: controller,
                          onChanged: filtrar,
                          decoration: InputDecoration(
                            labelText: "Buscar",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtradas.isEmpty
                            ? const Center(child: Text("Sin resultados"))
                            : ListView.separated(
                                itemCount: filtradas.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final cat = filtradas[i];
                                  return ListTile(
                                    title: Text(cat),
                                    onTap: () => Navigator.pop(ctx, cat),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  double? _parseMonto(String s) {
    // acepta coma o punto
    final cleaned = s.replaceAll(',', '.').trim();
    return double.tryParse(cleaned);
  }

  Future<double> _saldoDisponibleHastaFecha({
    required int clientId,
    required DateTime fecha,
  }) async {
    // saldo = ingresos - gastos (hasta esa fecha inclusive)
    final db = await database.db;
    final fechaStr = _formatDate(fecha);

    final ingresosResult = await db.rawQuery(
      '''
      SELECT SUM(monto) as total
      FROM movimientos
      WHERE client_id = ? AND tipo = 'ingreso' AND fecha <= ?
      ''',
      [clientId, fechaStr],
    );

    final gastosResult = await db.rawQuery(
      '''
      SELECT SUM(monto) as total
      FROM movimientos
      WHERE client_id = ? AND tipo = 'gasto' AND fecha <= ?
      ''',
      [clientId, fechaStr],
    );

    final ingresos = (ingresosResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final gastos = (gastosResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return ingresos - gastos;
  }

  Future<void> guardar() async {
    final formOk = formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    if (clientIdSeleccionado == null ||
        tipoSeleccionado == null ||
        categoriaSeleccionada == null ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa cliente, tipo, categoría y fecha."),
        ),
      );
      return;
    }

    final monto = _parseMonto(montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Monto inválido. Debe ser mayor a 0.")),
      );
      return;
    }

    // Validación principal: si es gasto no debe superar saldo disponible
    if (tipoSeleccionado == "gasto") {
      double saldo = await _saldoDisponibleHastaFecha(
        clientId: clientIdSeleccionado!,
        fecha: fechaSeleccionada!,
      );

      // Si estoy editando un gasto existente, “devuelvo” el gasto actual para recalcular
      if (editingMov != null &&
          editingMov!.tipo.toLowerCase().trim() == "gasto") {
        saldo += editingMov!.monto;
      }

      if (monto > saldo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No puedes gastar más de lo disponible.\n"
              "Disponible: \$${saldo.toStringAsFixed(2)}",
            ),
          ),
        );
        return;
      }
    }

    final mov = MovimientosModels(
      id: editingMov?.id,
      clientId: clientIdSeleccionado!,
      tipo: tipoSeleccionado!, // ingreso | gasto
      monto: monto,
      categoria: categoriaSeleccionada!,
      descripcion: descripcionController.text.trim(),
      fecha: _formatDate(fechaSeleccionada!),
    );

    try {
      if (editingMov == null) {
        await movimientosRepo.create(mov);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Movimiento creado ✅")));
      } else {
        await movimientosRepo.edit(mov);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Movimiento actualizado ✅")),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error guardando: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    _leerArgumentosSiExisten();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editingMov == null ? "Nuevo movimiento" : "Editar movimiento",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // CLIENTE
                DropdownButtonFormField<int>(
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
                  onChanged: (value) =>
                      setState(() => clientIdSeleccionado = value),
                  validator: (v) => v == null ? "Seleccione un cliente" : null,
                  decoration: InputDecoration(
                    labelText: "Cliente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // TIPO (LISTA)
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: "ingreso", child: Text("Ingreso")),
                    DropdownMenuItem(value: "gasto", child: Text("Gasto")),
                  ],
                  onChanged: (value) =>
                      setState(() => tipoSeleccionado = value),
                  validator: (v) => v == null ? "Seleccione tipo" : null,
                  decoration: InputDecoration(
                    labelText: "Tipo",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.swap_vert),
                  ),
                ),
                const SizedBox(height: 15),

                // MONTO
                TextFormField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese el monto";
                    }
                    final m = _parseMonto(value);
                    if (m == null || m <= 0) return "Monto inválido";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Monto",
                    hintText: "Ej: 25.50",
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // CATEGORÍA (LISTA CON SCROLL + SEARCH)
                InkWell(
                  onTap: () async {
                    final selected = await elegirCategoriaConBusqueda();
                    if (selected == null) return;
                    setState(() => categoriaSeleccionada = selected);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Categoría",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoriaSeleccionada ?? "Seleccione una categoría",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    categoriaSeleccionada == null ? "Obligatorio" : "",
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 10),

                // DESCRIPCIÓN
                TextFormField(
                  controller: descripcionController,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese descripción";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Descripción",
                    hintText: "Ej: Pago de internet / Sueldo / etc.",
                    prefixIcon: const Icon(Icons.text_fields),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // FECHA (DATE PICKER)
                TextFormField(
                  controller: fechaController,
                  readOnly: true,
                  onTap: pickFecha,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Seleccione una fecha";
                    }
                    final dt = DateTime.tryParse(value.trim());
                    if (dt == null) return "Fecha inválida";

                    if (dt.year != currentYear) {
                      return "La fecha debe ser del año $currentYear";
                    }
                    final hoy = DateTime(today.year, today.month, today.day);
                    final d2 = DateTime(dt.year, dt.month, dt.day);
                    if (d2.isAfter(hoy)) {
                      return "No puede ser una fecha futura";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Fecha",
                    hintText: "Selecciona fecha",
                    prefixIcon: const Icon(Icons.date_range),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // BOTONES
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: guardar,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(editingMov == null ? "Crear" : "Guardar"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Cancelar"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
