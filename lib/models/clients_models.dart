class ClientsModels {
  int? id;
  String cedula;
  String nombre;
  String direccion;
  String telefono;
  String correo;
  String fechanacimiento;

  //constructor de la clase
  ClientsModels({
    this.id,
    required this.cedula,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.fechanacimiento,
  });

  //crearmos 2 funciones
  //convertit de map a class (SELECT)
  factory ClientsModels.fromMap(Map<String, dynamic> data) {
    return ClientsModels(
      id: data["id"],
      cedula: data["cedula"],
      nombre: data["nombre"],
      direccion: data["direccion"],
      telefono: data["telefono"],
      correo: data["correo"],
      fechanacimiento: data["fechanacimiento"],
    );
  }

  //convertir de class a map (INSERT, UPDATE)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedula': cedula,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'fechanacimiento': fechanacimiento,
    };
  }
}
