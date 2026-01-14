import 'package:flutter/material.dart';
import '../../models/movimientos_models.dart';
import '../../repositories/movimientos_repository.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientosRepository repo = MovimientosRepository();

  List<MovimientosModels> movimientos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarMovimientos();
  }

  Future<void> cargarMovimientos() async {
    setState(() => cargando = true);
    try {
      movimientos = await repo.getAll();

      // opcional: ordenar por fecha desc (si fecha es YYYY-MM-DD)
      movimientos.sort((a, b) => (b.fecha).compareTo(a.fecha));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cargando movimientos: $e")));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> irANuevo() async {
    await Navigator.pushNamed(context, '/movimientos/form');
    await cargarMovimientos();
  }

  Future<void> irAEditar(MovimientosModels mov) async {
    await Navigator.pushNamed(context, '/movimientos/form', arguments: mov);
    await cargarMovimientos();
  }

  Future<void> confirmarEliminar(MovimientosModels mov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text(
          "¿Seguro que deseas eliminar este movimiento?\n\n"
          "Tipo: ${mov.tipo}\n"
          "Monto: \$${mov.monto.toStringAsFixed(2)}\n"
          "Categoría: ${mov.categoria}\n"
          "Fecha: ${mov.fecha}",
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
      if (mov.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo eliminar: id nulo")),
        );
        return;
      }
      await repo.delete(mov.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Movimiento eliminado ✅")));
      await cargarMovimientos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error eliminando: $e")));
    }
  }

  IconData _iconTipo(String tipo) {
    final t = tipo.toLowerCase().trim();
    if (t == "ingreso") return Icons.arrow_circle_up;
    if (t == "gasto") return Icons.arrow_circle_down;
    return Icons.swap_vert;
  }

  Color _colorTipo(String tipo) {
    final t = tipo.toLowerCase().trim();
    if (t == "ingreso") return Colors.green;
    if (t == "gasto") return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de movimientos"),
        actions: [
          IconButton(
            tooltip: "Recargar",
            onPressed: cargarMovimientos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : movimientos.isEmpty
          ? const Center(child: Text("No existen datos"))
          : RefreshIndicator(
              onRefresh: cargarMovimientos,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: movimientos.length,
                itemBuilder: (context, i) {
                  final mov = movimientos[i];

                  return Card(
                    child: ListTile(
                      onTap: () => irAEditar(mov), // tap = editar rápido
                      leading: Icon(
                        _iconTipo(mov.tipo),
                        color: _colorTipo(mov.tipo),
                        size: 32,
                      ),
                      title: Text(
                        "${mov.tipo.toUpperCase()}  -  \$${mov.monto.toStringAsFixed(2)}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${mov.categoria} | ${mov.fecha}\n${mov.descripcion}",
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
                            onPressed: () => irAEditar(mov),
                          ),
                          IconButton(
                            tooltip: "Eliminar",
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmarEliminar(mov),
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
