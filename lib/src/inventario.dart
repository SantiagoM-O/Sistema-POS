// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({Key? key}) : super(key: key);

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  int _limit = 10;
  int _offset = 0;
  int _totalProductos = 0;
  int _totalPages = 0;
  int _currentPage = 1;
  bool en_busqueda = false;

  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<int> _limitesOpciones =
      List<int>.generate(20, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _initializePagination();
  }

  Future<void> _initializePagination() async {
    setState(() {
      _isLoading = true;
    });

    _totalProductos = await dbHelper.getTotalProductos();
    _totalPages = (_totalProductos / _limit).ceil();

    await _loadProductos();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProductos() async {
    if (_searchQuery.isEmpty) {
      _productos = await dbHelper.getProductosPaginados(_limit, _offset);
      _totalPages = (_totalProductos / _limit).ceil();
    } else {
      _productos = await dbHelper.getProductoCoBa(_searchQuery);
      _totalPages = 1;
      _currentPage = 1;
    }
    setState(() {});
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _offset = (_currentPage - 1) * _limit;
      });
      _loadProductos();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _offset = (_currentPage - 1) * _limit;
      });
      _loadProductos();
    }
  }

  Future<void> _buscarProducto(String codigoBarras) async {
    setState(() {
      _searchQuery = codigoBarras;
      _offset = 0;
      _currentPage = 1;
    });
    await _loadProductos();
  }

  Future<void> _resetBusqueda() async {
    setState(() {
      _searchQuery = '';
      _offset = 0;
      _currentPage = 1;
    });
    await _initializePagination();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            buildProfileImage(),
            const SizedBox(width: 10),
            Text('Inventario'),
          ],
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _mostrarDialogoBusqueda(context);
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? Center(child: Text('No hay productos en la base de datos'))
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 20, right: 20, top: 35),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: const Color.fromARGB(255, 53, 52, 52)),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Código Barras')),
                                DataColumn(label: Text('Descripción')),
                                DataColumn(label: Text('Precio Compra')),
                                DataColumn(label: Text('Precio Venta')),
                                DataColumn(label: Text('Utilidad')),
                                DataColumn(label: Text('Existencia')),
                                DataColumn(label: Text('Opciones')),
                              ],
                              rows: _productos.map((producto) {
                                final utilidad =
                                    (producto['precio_venta'] as double) -
                                        (producto['precio_compra'] as double);
                                return DataRow(cells: [
                                  DataCell(Text(producto['id'].toString())),
                                  DataCell(Text(producto['codigo_barras'])),
                                  DataCell(Text(producto['descripcion'])),
                                  DataCell(Text(
                                      producto['precio_compra'].toString())),
                                  DataCell(Text(
                                      producto['precio_venta'].toString())),
                                  DataCell(Text(utilidad.toString())),
                                  DataCell(
                                      Text(producto['existencia'].toString())),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditDialog(context, producto,
                                              producto['id']);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          _confirmDelete(
                                              context, producto['id']);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.paste_rounded),
                                        onPressed: () {
                                          _showCopyDialog(context, producto,
                                              producto['id']);
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (en_busqueda)
                                ElevatedButton(
                                  onPressed: () async {
                                    await _resetBusqueda();
                                    en_busqueda = false;
                                  },
                                  child: Text('Cancelar Busqueda'),
                                )
                              else ...[
                                ElevatedButton(
                                  onPressed:
                                      _currentPage > 1 ? _previousPage : null,
                                  child: Text('Anterior'),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: _currentPage < _totalPages
                                      ? _nextPage
                                      : null,
                                  child: Text('Siguiente'),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text('Paginación : '),
                                  DropdownButton<int>(
                                    value: _limit,
                                    items: _limitesOpciones.map((int value) {
                                      return DropdownMenuItem<int>(
                                        value: value,
                                        child: Text(value.toString()),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _limit = newValue;
                                          _offset = 0;
                                          _currentPage = 1;
                                        });
                                        _initializePagination();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(width: 20),
                              Text('Página $_currentPage de $_totalPages'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showInputDialog(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _mostrarDialogoBusqueda(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String codigoBarras = '';
        return AlertDialog(
          title: Text('Buscar Producto por Código de Barras'),
          content: TextField(
            onChanged: (value) {
              codigoBarras = value;
            },
            decoration:
                InputDecoration(hintText: "Ingrese el código de barras"),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetBusqueda();
              },
            ),
            TextButton(
              child: Text('Buscar'),
              onPressed: () async {
                Navigator.of(context).pop();
                if (codigoBarras.isNotEmpty) {
                  await _buscarProducto(codigoBarras);
                  en_busqueda = true;
                } else {
                  await _resetBusqueda();
                  en_busqueda = false;
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showInputDialog(BuildContext context) {
    final TextEditingController codigoBarrasController =
        TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController precioCompraController =
        TextEditingController();
    final TextEditingController precioVentaController = TextEditingController();
    final TextEditingController existenciaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar Información   -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Código Barras', codigoBarrasController,
                    TextInputType.text),
                _buildTextField(
                    'Descripción', descripcionController, TextInputType.text),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Precio Compra',
                            precioCompraController, TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField('Precio Venta',
                            precioVentaController, TextInputType.number)),
                  ],
                ),
                _buildTextField(
                    'Existencia', existenciaController, TextInputType.number),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (codigoBarrasController.text.isEmpty ||
                    descripcionController.text.isEmpty ||
                    precioCompraController.text.isEmpty ||
                    precioVentaController.text.isEmpty ||
                    existenciaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Todos los campos son obligatorios')),
                  );
                } else if (double.tryParse(precioCompraController.text) ==
                        null ||
                    double.tryParse(precioVentaController.text) == null ||
                    int.tryParse(existenciaController.text) == null ||
                    double.parse(precioCompraController.text) < 0 ||
                    double.parse(precioVentaController.text) < 0 ||
                    int.parse(existenciaController.text) < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingresa valores válidos')),
                  );
                } else {
                  Map<String, dynamic> producto = {
                    'codigo_barras': codigoBarrasController.text,
                    'descripcion': descripcionController.text,
                    'precio_compra':
                        double.tryParse(precioCompraController.text) ?? 0.0,
                    'precio_venta':
                        double.tryParse(precioVentaController.text) ?? 0.0,
                    'existencia': int.tryParse(existenciaController.text) ?? 0,
                  };

                  DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.insertProducto(producto);
                  await _initializePagination();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Producto guardado exitosamente')),
                  );

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content:
              const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(
              onPressed: () async {
                await dbHelper.deleteProducto(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Producto eliminado exitosamente')),
                );
                Navigator.of(context).pop();
                await _initializePagination();
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, producto, id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, dynamic>? producto = await dbHelper.getProductoById(id);

    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
      return;
    }

    final TextEditingController codigoBarrasController =
        TextEditingController(text: producto['codigo_barras']);
    final TextEditingController descripcionController =
        TextEditingController(text: producto['descripcion']);
    final TextEditingController precioCompraController =
        TextEditingController(text: producto['precio_compra'].toString());
    final TextEditingController precioVentaController =
        TextEditingController(text: producto['precio_venta'].toString());
    final TextEditingController existenciaController =
        TextEditingController(text: producto['existencia'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar Información   -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Código Barras', codigoBarrasController,
                    TextInputType.text),
                _buildTextField(
                    'Descripción', descripcionController, TextInputType.text),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Precio Compra',
                            precioCompraController, TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField('Precio Venta',
                            precioVentaController, TextInputType.number)),
                  ],
                ),
                _buildTextField(
                    'Existencia', existenciaController, TextInputType.number),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (double.tryParse(precioCompraController.text) == null ||
                    double.tryParse(precioVentaController.text) == null ||
                    int.tryParse(existenciaController.text) == null ||
                    double.parse(precioCompraController.text) < 0 ||
                    double.parse(precioVentaController.text) < 0 ||
                    int.parse(existenciaController.text) < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingresa valores válidos')),
                  );
                } else {
                  if (double.tryParse(precioCompraController.text) == null) {}

                  Map<String, dynamic> producto = {
                    'codigo_barras': codigoBarrasController.text,
                    'descripcion': descripcionController.text,
                    'precio_compra':
                        double.tryParse(precioCompraController.text) ?? 0.0,
                    'precio_venta':
                        double.tryParse(precioVentaController.text) ?? 0.0,
                    'existencia': int.tryParse(existenciaController.text) ?? 0,
                  };

                  await dbHelper.updateProducto(id, producto);

                  _loadProductos();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Producto guardado exitosamente')),
                  );

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showCopyDialog(BuildContext context, producto, id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, dynamic>? producto = await dbHelper.getProductoById(id);

    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
      return;
    }

    final TextEditingController codigoBarrasController =
        TextEditingController(text: producto['']);
    final TextEditingController descripcionController =
        TextEditingController(text: producto['descripcion']);
    final TextEditingController precioCompraController =
        TextEditingController(text: producto['precio_compra'].toString());
    final TextEditingController precioVentaController =
        TextEditingController(text: producto['precio_venta'].toString());
    final TextEditingController existenciaController =
        TextEditingController(text: producto['existencia'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar Información   -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Código Barras', codigoBarrasController,
                    TextInputType.text),
                _buildTextField(
                    'Descripción', descripcionController, TextInputType.text),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Precio Compra',
                            precioCompraController, TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField('Precio Venta',
                            precioVentaController, TextInputType.number)),
                  ],
                ),
                _buildTextField(
                    'Existencia', existenciaController, TextInputType.number),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (double.tryParse(precioCompraController.text) == null ||
                    double.tryParse(precioVentaController.text) == null ||
                    int.tryParse(existenciaController.text) == null ||
                    double.parse(precioCompraController.text) < 0 ||
                    double.parse(precioVentaController.text) < 0 ||
                    int.parse(existenciaController.text) < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingresa valores válidos')),
                  );
                } else {
                  if (double.tryParse(precioCompraController.text) == null) {}

                  Map<String, dynamic> producto = {
                    'codigo_barras': codigoBarrasController.text,
                    'descripcion': descripcionController.text,
                    'precio_compra':
                        double.tryParse(precioCompraController.text) ?? 0.0,
                    'precio_venta':
                        double.tryParse(precioVentaController.text) ?? 0.0,
                    'existencia': int.tryParse(existenciaController.text) ?? 0,
                  };

                  await dbHelper.insertProducto(producto);

                  await _initializePagination();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Producto guardado exitosamente')),
                  );

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, TextInputType inputType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}
