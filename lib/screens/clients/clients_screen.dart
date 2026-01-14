import 'package:flutter/material.dart';
import '../../models/clients_models.dart';
import '../../repositories/clients_repository.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientsRepository repo = ClientsRepository();

  List<ClientsModels> clientes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    setState(() => cargando = true);
    try {
      clientes = await repo.getAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cargando clientes: $e")));
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> irANuevo() async {
    await Navigator.pushNamed(context, '/clients/form');
    await cargarClientes();
  }

  Future<void> irAEditar(ClientsModels cliente) async {
    // En el form vamos a recibir este argumento para precargar datos
    await Navigator.pushNamed(context, '/clients/form', arguments: cliente);
    await cargarClientes();
  }

  Future<void> confirmarEliminar(ClientsModels cliente) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text(
          "¿Seguro que deseas eliminar a:\n\n${cliente.nombre}\nCédula: ${cliente.cedula}\n\n"
          "Esto también eliminará sus movimientos (ingresos/gastos) por la relación.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await repo.delete(cliente.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cliente eliminado ✅")));
      await cargarClientes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error eliminando: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de clientes"),
        actions: [
          IconButton(
            tooltip: "Recargar",
            onPressed: cargarClientes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
          ? const Center(child: Text("No existen datos"))
          : RefreshIndicator(
              onRefresh: cargarClientes,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: clientes.length,
                itemBuilder: (context, i) {
                  final c = clientes[i];

                  return Card(
                    child: ListTile(
                      onTap: () => irAEditar(c), // tap rápido para editar
                      title: Text(
                        c.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Cédula: ${c.cedula}\nTel: ${c.telefono}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            tooltip: "Editar",
                            icon: const Icon(Icons.edit),
                            onPressed: () => irAEditar(c),
                          ),
                          IconButton(
                            tooltip: "Eliminar",
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: (c.id == null)
                                ? null
                                : () => confirmarEliminar(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: irANuevo,
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
