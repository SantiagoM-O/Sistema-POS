import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'productos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  //Método para crear la tabla
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_barras TEXT UNIQUE,
        descripcion TEXT,
        precio_compra REAL,
        precio_venta REAL,
        existencia INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE  clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        telefono TEXT,
        correo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ordenes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER,
        fecha TEXT,
        estado TEXT,
        pagado INTEGER,
        total_pagar INTEGER,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE productos_ordenes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER,
        producto_id INTEGER,
        descripcion TEXT,
        cantidad INTEGER,
        precio_unitario REAL,
        FOREIGN KEY (orden_id) REFERENCES ordenes(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');

    await _insertSampleData(db);

    Future close() async {
      final db = await database;
      db.close();
    }
  }

  /// ----------------   Métodos para productos--------------------------- ///

  // Método para obtener productos con paginación
  Future<List<Map<String, dynamic>>> getProductosPaginados(
      int limit, int offset) async {
    Database db = await database;
    return await db.query(
      'productos',
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
  }

  // Método para contar el total de productos
  Future<int> getTotalProductos() async {
    Database db = await database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM productos')) ??
        0;
  }

  //Método para Retorna una lista de todos los registros en la tabla
  Future<List<Map<String, dynamic>>> getProductos() async {
    Database db = await database;
    return await db.query('productos');
  }

  // Método para insertar un nuevo registro en la tabla productos y retorna el id del registro insertado.
  Future<int> insertProducto(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await db.insert('productos', row);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        print('Error: El código de barras ya existe.');
      } else {
        print('Error de base de datos: $e');
      }
      return -1;
    } catch (e) {
      print('Error al insertar producto: $e');
      return -1;
    }
  }

  // Método para actualizar un producto
  Future<int> updateProducto(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'productos',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para eliminar un producto
  Future<int> deleteProducto(int id) async {
    Database db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener un producto por su ID
  Future<Map<String, dynamic>?> getProductoById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Buscar productos por descripción
  Future<List<Map<String, dynamic>>> searchProductos(String query) async {
    Database db = await database;
    return await db.query(
      'productos',
      where: 'descripcion LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Buscar productos por codigo barras
  Future<List<Map<String, dynamic>>> getProductoCoBa(
      String codigo_barras) async {
    Database db = await database;
    return await db.query(
      'productos',
      where: 'codigo_barras LIKE ?',
      whereArgs: ['%$codigo_barras%'],
    );
  }

  //obtener órdenes de un cliente
  Future<List<Map<String, dynamic>>> getOrdenesConProductos(
      int clienteId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT ordenes.id AS orden_id, ordenes.fecha, ordenes.estado,
           productos.id AS producto_id, productos.descripcion, productos_ordenes.cantidad, productos_ordenes.precio_unitario
    FROM ordenes
    JOIN productos_ordenes ON ordenes.id = productos_ordenes.orden_id
    JOIN productos ON productos_ordenes.producto_id = productos.id
    WHERE ordenes.cliente_id = ?
  ''', [clienteId]);
  }

  /// ----------------   Métodos para clientes--------------------------- ///

  // Método para contar el total de clientes
  Future<int> getTotalClientes() async {
    final db = await database;

    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM clientes')) ??
        0;
  }

  //Método para Retorna una lista de todos los clientes en la tabla
  Future<List<Map<String, dynamic>>> getClientes() async {
    Database db = await database;
    return await db.query(
      'clientes',
      orderBy: 'id ASC',
    );
  }

  // Método para insertar un nuevo registro en la tabla cliente y retorna el id del registro insertado.
  Future<int> insertClientes(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await db.insert('clientes', row);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        print('Error: El código de barras ya existe.');
      } else {
        print('Error de base de datos: $e');
      }
      return -1;
    } catch (e) {
      print('Error al insertar producto: $e');
      return -1;
    }
  }

  // Método para actualizar un cliente
  Future<int> updateCliente(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'clientes',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para eliminar un cliente
  Future<int> deleteCliente(int id) async {
    Database db = await database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener un cliente por su ID
  Future<Map<String, dynamic>?> getClienteById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Buscar clientes por nombre
  Future<List<Map<String, dynamic>>> searchCliente(String query) async {
    Database db = await database;
    return await db.query(
      'clientes',
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Método para obtener clientes con paginación
  Future<List<Map<String, dynamic>>> getClientesPaginados(
      int limit, int offset) async {
    Database db = await database;
    return await db.query(
      'clientes',
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ----------------   Métodos para ordenes--------------------------- ///

  // crear nueva orden
  Future<void> crearOrden(int clienteId, int abonado, int total_pagar,
      String estado, List<Map<String, dynamic>> productos) async {
    DateTime now = DateTime.now();

    final db = await database;
    await db.transaction((txn) async {
      int ordenId = await txn.insert('ordenes', {
        'cliente_id': clienteId,
        'fecha':
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        'estado': estado,
        'pagado': abonado,
        'total_pagar': total_pagar,
      });

      for (var producto in productos) {
        await txn.insert('productos_ordenes', {
          'orden_id': ordenId,
          'producto_id': producto['producto_id'],
          'cantidad': producto['cantidad'],
          'precio_unitario': producto['precio_unitario'],
          'descripcion': producto['descripcion'],
        });
      }
    });
  }

//Obtener todas las órdenes
  Future<List<Map<String, dynamic>>> getOrdenes() async {
    Database db = await database;
    return await db.query('ordenes');
  }

//Obtener todas las órdenes Pendientes
  Future<List<Map<String, dynamic>>> getOrdenesPendientes() async {
    Database db = await database;
    return await db
        .query('ordenes', where: 'estado = ?', whereArgs: ['pendiente']);
  }

//Actualizar una orden
  Future<int> updateOrden(int id, Map<String, dynamic> orden) async {
    Database db = await database;
    return await db.update('ordenes', orden, where: 'id = ?', whereArgs: [id]);
  }

//Eliminar una orden
  Future<int> deleteOrden(int id) async {
    Database db = await database;
    return await db.delete('ordenes', where: 'id = ?', whereArgs: [id]);
  }

//Actualizar un producto en una orden
  Future<int> actualizarProductoEnOrden(
      int id, Map<String, dynamic> productoOrden) async {
    final db = await database;
    return await db.update('productos_ordenes', productoOrden,
        where: 'id = ?', whereArgs: [id]);
  }

//Eliminar un producto de una orden
  Future<int> eliminarProductoDeOrden(int id) async {
    final db = await database;
    return await db
        .delete('productos_ordenes', where: 'id = ?', whereArgs: [id]);
  }

  /// ----------------   Métodos para productos de ordenes--------------------------- ///
  ///
//metodo para insertar un producto de una orden
  Future<int> insertProductoOrden(Map<String, dynamic> productoOrden) async {
    Database db = await database;
    return await db.insert('productos_ordenes', productoOrden);
  }

//metodo para Obtener todas las productos
  Future<List<Map<String, dynamic>>> getProductosOrdenes() async {
    Database db = await database;
    return await db.query('productos_ordenes');
  }

  // Método para obtener productos de una orden específica
  Future<List<Map<String, dynamic>>> getProductosDeOrden(int ordenId) async {
    Database db = await database;
    return await db.query(
      'productos_ordenes',
      where: 'orden_id = ?',
      whereArgs: [ordenId],
    );
  }

//Actualizar un producto en una orden
  Future<int> updateProductoOrden(
      int id, Map<String, dynamic> productoOrden) async {
    Database db = await database;
    return await db.update('productos_ordenes', productoOrden,
        where: 'id = ?', whereArgs: [id]);
  }

//Eliminar un producto en una orden
  Future<int> deleteProductoOrden(int id) async {
    Database db = await database;
    return await db
        .delete('productos_ordenes', where: 'id = ?', whereArgs: [id]);
  }

  /// ----------------   Métodos para las graficas  --------------------------- ///

// Método para obtener los productos ordenados de más vendido a menos
  Future<List<Map<String, dynamic>>> getProductosMasVendido() async {
    final db = await _initDatabase();
    final result = await db.rawQuery('''
    SELECT 
        producto_id,
        descripcion,
        SUM(cantidad) AS total_vendido,
        SUM(cantidad * precio_unitario) AS total_precio
    FROM 
        productos_ordenes
    GROUP BY 
        producto_id, descripcion
    ORDER BY 
        total_vendido DESC;
  ''');
    return result;
  }

// Método para obtener los clientes ordenados de más valor comprado a menos
  Future<List<Map<String, dynamic>>> getClientesConMasCompras() async {
    final db = await _initDatabase();
    final result = await db.rawQuery('''
    SELECT 
        clientes.id,
        clientes.nombre,
        SUM(productos_ordenes.cantidad) AS cantidad_productos,
        SUM(productos_ordenes.cantidad * productos_ordenes.precio_unitario) AS total_precio
    FROM 
        clientes
    JOIN 
        ordenes ON clientes.id = ordenes.cliente_id
    JOIN 
        productos_ordenes ON ordenes.id = productos_ordenes.orden_id
    GROUP BY 
        clientes.id, clientes.nombre
    ORDER BY 
        cantidad_productos DESC;
  ''');
    return result;
  }

// Método para obtener los clientes ordenados de más productos comprados a menos
  Future<List<Map<String, dynamic>>>
      getClientesOrdenadosPorProductosComprados() async {
    final db = await _initDatabase();
    final result = await db.rawQuery('''
    SELECT 
        clientes.id,
        clientes.nombre,
        SUM(productos_ordenes.cantidad) AS cantidad_productos
    FROM 
        clientes
    JOIN 
        ordenes ON clientes.id = ordenes.cliente_id
    JOIN 
        productos_ordenes ON ordenes.id = productos_ordenes.orden_id
    GROUP BY 
        clientes.id, clientes.nombre
    ORDER BY 
        cantidad_productos DESC;
  ''');
    return result;
  }

  /// METODOS PARA INFORMES OTROS
  /// metodo cliente mas compro
  Future<Map<String, dynamic>?> getClienteMasComprador() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT c.id, c.nombre, SUM(po.cantidad * po.precio_unitario) AS total_gastado
    FROM clientes AS c
    JOIN ordenes AS o ON c.id = o.cliente_id
    JOIN productos_ordenes AS po ON o.id = po.orden_id
    GROUP BY c.id
    ORDER BY total_gastado DESC
    LIMIT 1
  ''');

    return result.isNotEmpty ? result.first : null;
  }

// Obtener los productos más vendidos
  Future<List<Map<String, dynamic>>> getProductosMasVendidos(int limite) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT productos.descripcion, SUM(productos_ordenes.cantidad) AS cantidad_vendida
    FROM productos
    JOIN productos_ordenes ON productos.id = productos_ordenes.producto_id
    GROUP BY productos.id
    ORDER BY cantidad_vendida DESC
    LIMIT ?
  ''', [limite]);
    return result;
  }

// Obtener los productos menos vendidos
  Future<List<Map<String, dynamic>>> getProductosMenosVendidos(
      int limite) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT productos.descripcion, SUM(productos_ordenes.cantidad) AS cantidad_vendida
    FROM productos
    JOIN productos_ordenes ON productos.id = productos_ordenes.producto_id
    GROUP BY productos.id
    ORDER BY cantidad_vendida ASC
    LIMIT ?
  ''', [limite]);
    return result;
  }

  // Método para obtener los productos comprados por un cliente específico
  Future<List<Map<String, dynamic>>> getProductosCompradosPorCliente(
      int clienteId) async {
    final db = await database;

    final List<Map<String, dynamic>> productos = await db.rawQuery('''
    SELECT p.id AS producto_id, p.descripcion, po.cantidad, po.precio_unitario
    FROM productos_ordenes AS po
    JOIN productos AS p ON po.producto_id = p.id
    JOIN ordenes AS o ON po.orden_id = o.id
    WHERE o.cliente_id = ?
  ''', [clienteId]);

    return productos;
  }

  /// metodos 5 clientes
  Future<List<Map<String, dynamic>>> getMejoresClientes(int limit) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT c.id, c.nombre, SUM(po.cantidad * po.precio_unitario) AS total_gastado
    FROM clientes AS c
    JOIN ordenes AS o ON c.id = o.cliente_id
    JOIN productos_ordenes AS po ON o.id = po.orden_id
    GROUP BY c.id
    ORDER BY total_gastado DESC
    LIMIT ?
  ''', [limit]);

    return result;
  }

  /// ----------------   Métodos para insertar registros   --------------------------- ///

  // Método para insertar registros de ejemplo en la tabla
  Future<void> _insertSampleData(Database db) async {
    List<Map<String, dynamic>> sampleProducts = [
      {
        'codigo_barras': '001',
        'descripcion': 'Producto 1',
        'precio_compra': 10.0,
        'precio_venta': 15.0,
        'existencia': 100,
      },
      {
        'codigo_barras': '002',
        'descripcion': 'Producto 2',
        'precio_compra': 20.0,
        'precio_venta': 25.0,
        'existencia': 50,
      },
      {
        'codigo_barras': '003',
        'descripcion': 'Producto 3',
        'precio_compra': 30.0,
        'precio_venta': 40.0,
        'existencia': 75,
      },
      {
        'codigo_barras': '004',
        'descripcion': 'Producto 4',
        'precio_compra': 12.0,
        'precio_venta': 18.0,
        'existencia': 60,
      },
      {
        'codigo_barras': '005',
        'descripcion': 'Producto 5',
        'precio_compra': 22.0,
        'precio_venta': 28.0,
        'existencia': 80,
      },
      {
        'codigo_barras': '006',
        'descripcion': 'Producto 6',
        'precio_compra': 15.0,
        'precio_venta': 20.0,
        'existencia': 90,
      },
      {
        'codigo_barras': '007',
        'descripcion': 'Producto 7',
        'precio_compra': 25.0,
        'precio_venta': 35.0,
        'existencia': 40,
      },
      {
        'codigo_barras': '008',
        'descripcion': 'Producto 8',
        'precio_compra': 18.0,
        'precio_venta': 22.0,
        'existencia': 70,
      },
      {
        'codigo_barras': '009',
        'descripcion': 'Producto 9',
        'precio_compra': 28.0,
        'precio_venta': 38.0,
        'existencia': 55,
      },
      {
        'codigo_barras': '010',
        'descripcion': 'Producto 10',
        'precio_compra': 32.0,
        'precio_venta': 42.0,
        'existencia': 65,
      },
      {
        'codigo_barras': '011',
        'descripcion': 'Producto 11',
        'precio_compra': 14.0,
        'precio_venta': 19.0,
        'existencia': 85,
      },
      {
        'codigo_barras': '012',
        'descripcion': 'Producto 12',
        'precio_compra': 24.0,
        'precio_venta': 30.0,
        'existencia': 75,
      },
      {
        'codigo_barras': '013',
        'descripcion': 'Producto 13',
        'precio_compra': 16.0,
        'precio_venta': 21.0,
        'existencia': 95,
      },
      {
        'codigo_barras': '014',
        'descripcion': 'Producto 14',
        'precio_compra': 26.0,
        'precio_venta': 36.0,
        'existencia': 45,
      },
      {
        'codigo_barras': '015',
        'descripcion': 'Producto 15',
        'precio_compra': 19.0,
        'precio_venta': 23.0,
        'existencia': 85,
      },
      {
        'codigo_barras': '016',
        'descripcion': 'Producto 16',
        'precio_compra': 29.0,
        'precio_venta': 39.0,
        'existencia': 50,
      },
      {
        'codigo_barras': '017',
        'descripcion': 'Producto 17',
        'precio_compra': 33.0,
        'precio_venta': 43.0,
        'existencia': 60,
      },
      {
        'codigo_barras': '018',
        'descripcion': 'Producto 18',
        'precio_compra': 13.0,
        'precio_venta': 17.0,
        'existencia': 70,
      },
      {
        'codigo_barras': '019',
        'descripcion': 'Producto 19',
        'precio_compra': 23.0,
        'precio_venta': 29.0,
        'existencia': 80,
      },
      {
        'codigo_barras': '020',
        'descripcion': 'Producto 20',
        'precio_compra': 17.0,
        'precio_venta': 22.0,
        'existencia': 90,
      },
      {
        'codigo_barras': '021',
        'descripcion': 'Producto 21',
        'precio_compra': 27.0,
        'precio_venta': 37.0,
        'existencia': 55,
      },
      {
        'codigo_barras': '022',
        'descripcion': 'Producto 22',
        'precio_compra': 31.0,
        'precio_venta': 41.0,
        'existencia': 65,
      },
      {
        'codigo_barras': '023',
        'descripcion': 'Producto 23',
        'precio_compra': 11.0,
        'precio_venta': 16.0,
        'existencia': 75,
      },
    ];

    // Insertar solo si la tabla está vacía
    for (var product in sampleProducts) {
      await db.insert('productos', product);
    }

    List<Map<String, dynamic>> sampleClients = [
      {
        'nombre': 'Mostrador',
        'telefono': '0000000000',
        'correo': 'Mostrador@example.com'
      },
      {
        'nombre': 'Ana Gomez',
        'telefono': '3129737393',
        'correo': 'ana.gomez@example.com'
      },
      {
        'nombre': 'Luis Rodriguez',
        'telefono': '3149684731',
        'correo': 'luis.rodriguez@example.com'
      },
      {
        'nombre': 'Maria Lopez',
        'telefono': '3159871234',
        'correo': 'maria.lopez@example.com'
      },
      {
        'nombre': 'Carlos Martinez',
        'telefono': '3168765432',
        'correo': 'carlos.martinez@example.com'
      },
      {
        'nombre': 'Laura Sanchez',
        'telefono': '3171234567',
        'correo': 'laura.sanchez@example.com'
      },
      {
        'nombre': 'Pedro Ramirez',
        'telefono': '3187654321',
        'correo': 'pedro.ramirez@example.com'
      },
      {
        'nombre': 'Sofia Fernandez',
        'telefono': '3196543210',
        'correo': 'sofia.fernandez@example.com'
      },
      {
        'nombre': 'Jorge Morales',
        'telefono': '3108765432',
        'correo': 'jorge.morales@example.com'
      },
      {
        'nombre': 'Carmen Diaz',
        'telefono': '3119876543',
        'correo': 'carmen.diaz@example.com'
      },
      {
        'nombre': 'Julian Perez',
        'telefono': '3123456789',
        'correo': 'julian.perez@example.com'
      },
      {
        'nombre': 'Gabriela Castro',
        'telefono': '3134567890',
        'correo': 'gabriela.castro@example.com'
      },
      {
        'nombre': 'Miguel Torres',
        'telefono': '3145678901',
        'correo': 'miguel.torres@example.com'
      },
      {
        'nombre': 'Veronica Ruiz',
        'telefono': '3156789012',
        'correo': 'veronica.ruiz@example.com'
      },
      {
        'nombre': 'Daniela Vasquez',
        'telefono': '3167890123',
        'correo': 'daniela.vasquez@example.com'
      },
      {
        'nombre': 'Fernando Rios',
        'telefono': '3178901234',
        'correo': 'fernando.rios@example.com'
      },
      {
        'nombre': 'Patricia Flores',
        'telefono': '3189012345',
        'correo': 'patricia.flores@example.com'
      },
      {
        'nombre': 'Ricardo Gutierrez',
        'telefono': '3190123456',
        'correo': 'ricardo.gutierrez@example.com'
      },
      {
        'nombre': 'Elena Herrera',
        'telefono': '3102345678',
        'correo': 'elena.herrera@example.com'
      },
      {
        'nombre': 'Roberto Jimenez',
        'telefono': '3113456789',
        'correo': 'roberto.jimenez@example.com'
      },
      {
        'nombre': 'Isabel Romero',
        'telefono': '3124567890',
        'correo': 'isabel.romero@example.com'
      },
      {
        'nombre': 'Hector Peña',
        'telefono': '3135678901',
        'correo': 'hector.pena@example.com'
      },
      {
        'nombre': 'Valeria Mendez',
        'telefono': '3146789012',
        'correo': 'valeria.mendez@example.com'
      },
    ];

    // Insertar solo si la tabla está vacía
    for (var client in sampleClients) {
      await db.insert('clientes', client);
    }
  }
}
