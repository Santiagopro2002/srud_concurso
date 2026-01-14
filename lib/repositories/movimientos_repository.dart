import '../models/movimientos_models.dart';
import '../settings/database_connection.dart';

class MovimientosRepository {
  final tableName = "movimientos";
  final database = DatabaseConnection();

  //funicon para insertar datos
  Future<int> create(MovimientosModels data) async {
    final db = await database.db; //1ro. primero llamar ala coxion
    return await db.insert(
      tableName,
      data.toMap(),
    ); //2do. segundo ejecuto el sql
  }

  //funicon para editar datos
  Future<int> edit(MovimientosModels data) async {
    final db = await database.db; //1ro. primero llamar ala coxion
    return await db.update(
      tableName,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    ); //2do. segundo ejecuto el sql
  }

  //funicon para elimiar datos
  Future<int> delete(int id) async {
    final db = await database.db; //1ro. primero llamar ala coxion
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    ); //2do. segundo ejecuto el sql
  }

  //funcion para listar datos
  Future<List<MovimientosModels>> getAll() async {
    final db = await database.db; //1ro. primero llamar ala coxion
    final responce = await db.query(tableName); //2do. ejecuto el sql
    return responce
        .map((e) => MovimientosModels.fromMap(e))
        .toList(); //3r trasformar el json a clase
  }

  //funcion para listar movimientos por cliente
  Future<List<MovimientosModels>> getByClient(int clientId) async {
    final db = await database.db; //1ro. primero llamar ala coxion
    final responce = await db.query(
      tableName,
      where: 'client_id = ?',
      whereArgs: [clientId],
    ); //2do. ejecuto el sql
    return responce
        .map((e) => MovimientosModels.fromMap(e))
        .toList(); //3r trasformar el json a clase
  }
}
