// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';

class ClientePage extends StatefulWidget {
  const ClientePage({Key? key}) : super(key: key);

  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  int _limit = 10;
  int _offset = 0;
  int _totalClientes = 0;
  int _totalPages = 0;
  int _currentPage = 1;
  bool en_busqueda = false;

  List<Map<String, dynamic>> _clientes = [];
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

    _totalClientes = await dbHelper.getTotalClientes();
    _totalPages = (_totalClientes / _limit).ceil();

    await _loadClientes();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadClientes() async {
    if (_searchQuery.isEmpty) {
      _clientes = await dbHelper.getClientesPaginados(_limit, _offset);
      _totalPages = (_totalClientes / _limit).ceil();
    } else {
      _clientes = await dbHelper.searchCliente(_searchQuery);
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
      _loadClientes();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _offset = (_currentPage - 1) * _limit;
      });
      _loadClientes();
    }
  }

  Future<void> _buscarProducto(String nombre) async {
    setState(() {
      _searchQuery = nombre;
      _offset = 0;
      _currentPage = 1;
    });
    await _loadClientes();
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
            Text('Clientes'),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      drawer: buildDrawer(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar cliente por nombre',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        await _buscarProducto(value);
                        setState(() {
                          en_busqueda = true;
                        });
                      } else {
                        await _resetBusqueda();
                        setState(() {
                          en_busqueda = false;
                        });
                      }
                    },
                  ),
                ),
                if (_clientes.isEmpty && !en_busqueda)
                  Center(child: Text('No hay productos en la base de datos')),
                if (_clientes.isEmpty && en_busqueda)
                  Center(
                      child:
                          Text('No se encontraron productos para la búsqueda')),
                if (_clientes.isNotEmpty)
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
                              DataColumn(label: Text('Nombre Completo')),
                              DataColumn(label: Text('Número de teléfono')),
                              DataColumn(label: Text('Correo')),
                              DataColumn(label: Text('      Opciones')),
                            ],
                            rows: _clientes.map((cliente) {
                              return DataRow(cells: [
                                DataCell(Text(cliente['id'].toString())),
                                DataCell(Text(cliente['nombre'])),
                                DataCell(Text(cliente['telefono'].toString())),
                                DataCell(Text(cliente['correo'].toString())),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _showEditDialog(
                                            context, cliente, cliente['id']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _confirmDelete(context, cliente['id']);
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
                              onPressed:
                                  _currentPage < _totalPages ? _nextPage : null,
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

  void _showInputDialog(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController correoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar Información   -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Nombre', nombreController, TextInputType.text),
                _buildTextField(
                    'Teléfono', telefonoController, TextInputType.number),
                _buildTextField('Correo', correoController, TextInputType.text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (nombreController.text.isEmpty ||
                    telefonoController.text.isEmpty ||
                    correoController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Todos los campos son obligatorios')),
                  );
                } else {
                  Map<String, dynamic> cliente = {
                    'nombre': nombreController.text,
                    'telefono': telefonoController.text,
                    'correo': correoController.text,
                  };

                  DatabaseHelper dbHelper = DatabaseHelper();
                  await dbHelper.insertClientes(cliente);

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
                await dbHelper.deleteCliente(id);
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

  void _showEditDialog(BuildContext context, cliente, id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, dynamic>? cliente = await dbHelper.getClienteById(id);

    if (cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
      return;
    }

    final TextEditingController nombreController =
        TextEditingController(text: cliente['nombre']);
    final TextEditingController telefonoController =
        TextEditingController(text: cliente['telefono'].toString());
    final TextEditingController correoController =
        TextEditingController(text: cliente['correo']);

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar Información   -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Nombre', nombreController, TextInputType.text),
                _buildTextField(
                    'Teléfono', telefonoController, TextInputType.number),
                _buildTextField('Correo', correoController, TextInputType.text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (double.tryParse(telefonoController.text) == null ||
                    int.parse(telefonoController.text) < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingresa valores válidos')),
                  );
                } else {
                  Map<String, dynamic> cliente = {
                    'codigo_barras': nombreController.text,
                    'descripcion': correoController.text,
                    'existencia': int.tryParse(telefonoController.text) ?? 0,
                  };

                  await dbHelper.updateCliente(id, cliente);

                  _loadClientes();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cliente guardado exitosamente')),
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
