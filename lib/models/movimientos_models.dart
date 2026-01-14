class MovimientosModels {
  int? id;
  int clientId;
  String tipo;
  double monto;
  String categoria;
  String descripcion;
  String fecha;

  // constructor de la clase
  MovimientosModels({
    this.id,
    required this.clientId,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
  });

  // convertir de Map a Class (SELECT)
  factory MovimientosModels.fromMap(Map<String, dynamic> data) {
    return MovimientosModels(
      id: data["id"],
      clientId: data["client_id"],
      tipo: data["tipo"],
      monto: data["monto"] is String
          ? double.parse(data["monto"])
          : (data["monto"] as num).toDouble(),
      categoria: data["categoria"],
      descripcion: data["descripcion"],
      fecha: data["fecha"],
    );
  }

  // convertir de Class a Map (INSERT, UPDATE)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'tipo': tipo,
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': fecha,
    };
  }
}
