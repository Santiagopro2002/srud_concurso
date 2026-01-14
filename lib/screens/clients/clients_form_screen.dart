import 'package:flutter/material.dart';
import '../../models/clients_models.dart';
import '../../repositories/clients_repository.dart';

class ClientsFormScreen extends StatefulWidget {
  const ClientsFormScreen({super.key});

  @override
  State<ClientsFormScreen> createState() => _ClientsFormScreenState();
}

class _ClientsFormScreenState extends State<ClientsFormScreen> {
  final formKey = GlobalKey<FormState>();

  final cedulaController = TextEditingController();
  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final fechanacimientoController = TextEditingController();

  final ClientsRepository repo = ClientsRepository();

  ClientsModels? editingClient;
  DateTime? fechaNac;

  bool _argsLeidos = false;

  @override
  void dispose() {
    cedulaController.dispose();
    nombreController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    fechanacimientoController.dispose();
    super.dispose();
  }

  void _leerArgumentos() {
    if (_argsLeidos) return;
    _argsLeidos = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ClientsModels) {
      editingClient = args;

      cedulaController.text = args.cedula;
      nombreController.text = args.nombre;
      direccionController.text = args.direccion;
      telefonoController.text = args.telefono;
      correoController.text = args.correo;

      // fechanacimiento viene texto, intentamos parsear
      final parsed = DateTime.tryParse(args.fechanacimiento);
      if (parsed != null) {
        fechaNac = parsed;
        fechanacimientoController.text = _formatDate(parsed);
      } else {
        fechanacimientoController.text = args.fechanacimiento;
      }
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

  bool _validEmail(String email) {
    final e = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  bool _onlyDigits(String s) => RegExp(r'^\d+$').hasMatch(s);

  Future<void> pickFechaNacimiento() async {
    final today = DateTime.now();

    final initial =
        fechaNac ?? DateTime(today.year - 20, today.month, today.day);
    final firstDate = DateTime(1900, 1, 1);
    final lastDate = DateTime(today.year, today.month, today.day); // no futura

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: "Seleccione fecha de nacimiento",
    );

    if (picked == null) return;

    setState(() {
      fechaNac = picked;
      fechanacimientoController.text = _formatDate(picked);
    });
  }

  Future<void> guardar() async {
    final ok = formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (fechaNac == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione la fecha de nacimiento")),
      );
      return;
    }

    final client = ClientsModels(
      id: editingClient?.id,
      cedula: cedulaController.text.trim(),
      nombre: nombreController.text.trim(),
      direccion: direccionController.text.trim(),
      telefono: telefonoController.text.trim(),
      correo: correoController.text.trim(),
      fechanacimiento: _formatDate(fechaNac!),
    );

    try {
      if (editingClient == null) {
        await repo.create(client);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cliente creado ✅")));
      } else {
        await repo.edit(client);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cliente actualizado ✅")));
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
    _leerArgumentos();

    return Scaffold(
      appBar: AppBar(
        title: Text(editingClient == null ? "Nuevo cliente" : "Editar cliente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: cedulaController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Ingrese la cédula";
                    if (!_onlyDigits(v)) return "Solo números";
                    if (v.length != 10)
                      return "La cédula debe tener 10 dígitos";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Cédula",
                    hintText: "Ej: 0501234567",
                    prefixIcon: const Icon(Icons.numbers, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: nombreController,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Ingrese el nombre";
                    if (v.length < 3) return "Nombre muy corto";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Nombre",
                    hintText: "Ej: Juan Pérez",
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: direccionController,
                  maxLines: 3,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Ingrese la dirección";
                    if (v.length < 5) return "Dirección muy corta";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Dirección",
                    hintText: "Ej: Barrio Centro, Calle X...",
                    prefixIcon: const Icon(Icons.home, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Ingrese el teléfono";
                    if (!_onlyDigits(v)) return "Solo números";
                    if (v.length < 7 || v.length > 10) {
                      return "Teléfono inválido (7 a 10 dígitos)";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Teléfono",
                    hintText: "Ej: 0987654321",
                    prefixIcon: const Icon(Icons.phone, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Ingrese el correo";
                    if (!_validEmail(v)) return "Correo inválido";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Correo",
                    hintText: "Ej: correo@gmail.com",
                    prefixIcon: const Icon(Icons.email, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: fechanacimientoController,
                  readOnly: true,
                  onTap: pickFechaNacimiento,
                  validator: (value) {
                    final v = value?.trim() ?? "";
                    if (v.isEmpty) return "Seleccione fecha de nacimiento";
                    final dt = DateTime.tryParse(v);
                    if (dt == null) return "Fecha inválida";
                    final today = DateTime.now();
                    final d2 = DateTime(dt.year, dt.month, dt.day);
                    final hoy = DateTime(today.year, today.month, today.day);
                    if (d2.isAfter(hoy)) return "No puede ser fecha futura";
                    if (dt.year < 1900) return "Fecha inválida";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Fecha de nacimiento",
                    hintText: "YYYY-MM-DD",
                    prefixIcon: const Icon(
                      Icons.date_range,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: guardar,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          editingClient == null ? "Aceptar" : "Guardar",
                        ),
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
