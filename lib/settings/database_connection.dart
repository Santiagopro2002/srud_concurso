import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConnection {
  // Generando un constructor para el llamado
  static final DatabaseConnection instance = DatabaseConnection.internal();
  factory DatabaseConnection() => instance;

  // referencias internas
  DatabaseConnection.internal();

  // crear un llamado de la libreria sqflite
  static Database? database;

  // funcion para crear la conexion
  Future<Database> get db async {
    // retorna la conexion si ya existia una antes
    if (database != null) return database!;
    database = await inicializarDb(); // inicializa la conexion en la funcion
    return database!; // retorna la conexion con la nueva conexion
  }

  Future<Database> inicializarDb() async {
    final rutaDb = await getDatabasesPath(); // /data/emulated/0/gestion
    final rutaFinal = join(
      rutaDb,
      'administracionbd.db',
    ); // /data/emulated/0/gestion/gestion.db

    return await openDatabase(
      rutaFinal,
      version: 1,
      onCreate: (Database db, int version) async {
        // crear todos los scripts de la base de datos (tablas y/o datos iniciales)

        await db.execute('''
            CREATE TABLE clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              cedula TEXT NOT NULL, 
              nombre TEXT NOT NULL, 
              direccion TEXT NOT NULL, 
              telefono TEXT NOT NULL, 
              correo TEXT NOT NULL, 
              fechanacimiento TEXT NOT NULL 
            )
          ''');
        await db.execute('''
            CREATE TABLE movimientos (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              tipo TEXT NOT NULL, 
              monto REAL NOT NULL, 
              categoria TEXT NOT NULL, 
              descripcion TEXT NOT NULL, 
              fecha TEXT NOT NULL,
              client_id INTEGER NOT NULL,
              FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
            )
          ''');
      },
    );
  }
}
