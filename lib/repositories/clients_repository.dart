import '../models/clients_models.dart';
import '../settings/database_connection.dart';

class ClientsRepository {
  final tableName = "clients";
  final database = DatabaseConnection();

  //funicon para insertar datos
  Future<int> create(ClientsModels data) async {
    final db = await database.db; //1ro. primero llamar ala coxion
    return await db.insert(
      tableName,
      data.toMap(),
    ); //2do. segundo ejecuto el sql
  }

  //funicon para editar datos
  Future<int> edit(ClientsModels data) async {
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
  Future<List<ClientsModels>> getAll() async {
    final db = await database.db; //1ro. primero llamar ala coxion
    final responce = await db.query(tableName); //2do. ejecuto el sql
    return responce
        .map((e) => ClientsModels.fromMap(e))
        .toList(); //3r trasformar el json a clase
  }
}
