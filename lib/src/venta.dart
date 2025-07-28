// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';
import 'package:flutter/material.dart';

class VentaPage extends StatefulWidget {
  @override
  _VentaPageState createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  TextEditingController codigoBarrasController = TextEditingController();
  TextEditingController montoPagadoController = TextEditingController();
  List<Map<String, dynamic>> productosBuscados = [];
  List<Map<String, dynamic>> productosPaginados = [];
  List<Map<String, dynamic>> productosBuscadosEnviar = [];
  List<Map<String, dynamic>> clientes = [];
  String? clienteSeleccionado;
  bool limpiarpagina = false;

  int productosPorPagina = 5;
  int paginaActual = 0;
  int totalPaginas = 1;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  void _actualizarPaginacion() {
    setState(() {
      totalPaginas = (productosBuscados.length / productosPorPagina).ceil();
      int inicio = paginaActual * productosPorPagina;
      int fin = inicio + productosPorPagina;
      productosPaginados = productosBuscados.sublist(
        inicio,
        fin > productosBuscados.length ? productosBuscados.length : fin,
      );
    });
  }

  void _cambiarProductosPorPagina(int cantidad) {
    setState(() {
      productosPorPagina = cantidad;
      paginaActual = 0;
      _actualizarPaginacion();
    });
  }

  void _avanzarPagina() {
    if (paginaActual < totalPaginas - 1) {
      setState(() {
        paginaActual++;
        _actualizarPaginacion();
      });
    }
  }

  void _retrocederPagina() {
    if (paginaActual > 0) {
      setState(() {
        paginaActual--;
        _actualizarPaginacion();
      });
    }
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

  Future<void> cargarClientes() async {
    clientes = await dbHelper.getClientes();
    setState(() {});
  }

  double calcularTotalPagar(List<Map<String, dynamic>> productosBuscados) {
    double total = 0.0;
    for (var producto in productosBuscados) {
      total += producto['precio_venta'] * producto['productos_comprados'];
    }
    return total;
  }

  void mostrarMenuPago(List<Map<String, dynamic>> productosBuscados) async {
    double totalPagar = calcularTotalPagar(productosBuscados);

    int? idCliente;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("   Finalizar Venta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DropdownButtonFormField<String>(
                            value: clienteSeleccionado,
                            hint: Text("Seleccione un cliente"),
                            items: clientes.map((cliente) {
                              return DropdownMenuItem<String>(
                                value: cliente['id'].toString(),
                                child: Text(cliente['nombre']),
                              );
                            }).toList(),
                            onChanged: (nuevoValor) {
                              setState(() {
                                if (nuevoValor != null) {
                                  idCliente = int.tryParse(nuevoValor);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          _showInputDialog(context);
                          List<Map<String, dynamic>> nuevaLista =
                              await dbHelper.getClientes();
                          setState(() {
                            clientes = nuevaLista;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total a pagar:"),
                      Text("\$${totalPagar.toStringAsFixed(2)}"),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: montoPagadoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Monto pagado por el cliente"),
                    onChanged: (valor) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Monto a devolver:"),
                      Text(
                        "\$${_calcularMontoDevolver(totalPagar).toStringAsFixed(2)}",
                        style: TextStyle(
                            color: const Color.fromARGB(255, 221, 0, 0)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    clienteSeleccionado = null;
                    montoPagadoController.clear();
                  },
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    if (idCliente == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Por favor, seleccione un cliente.')),
                      );
                      return;
                    }

                    double? montoPagado =
                        double.tryParse(montoPagadoController.text);

                    if (montoPagado == null ||
                        montoPagado <= 0 ||
                        montoPagado < totalPagar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Por favor, ingrese un monto válido.')),
                      );
                      return;
                    }

                    Map<String, dynamic>? productoActuExis;

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Compra realizada exitosamente')),
                    );

                    for (var producto in productosBuscados) {
                      productosBuscadosEnviar.add({
                        'producto_id': producto['id'],
                        'cantidad': producto['productos_comprados'],
                        'precio_unitario': producto['precio_venta'],
                        'descripcion': producto['descripcion'],
                      });

                      productoActuExis =
                          await dbHelper.getProductoById(producto['id']);
                      int existenciasActuales = productoActuExis?['existencia'];
                      int pro_comp = producto['productos_comprados'];
                      int nuevasExistencias = existenciasActuales - pro_comp;
                      await dbHelper.updateProducto(
                          producto['id'], {'existencia': nuevasExistencias});
                    }

                    await dbHelper.crearOrden(
                      idCliente!,
                      totalPagar.toInt(),
                      montoPagado.toInt(),
                      'completado',
                      productosBuscadosEnviar,
                    );

                    confirmarYLimpiarTabla();

                    clienteSeleccionado = null;
                    montoPagadoController.clear();
                  },
                  child: Text("Finalizar Compra"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void mostrarMenuapartar(List<Map<String, dynamic>> productosBuscados) async {
    double totalPagar = calcularTotalPagar(productosBuscados);
    int? idCliente;
    double? montoAbonado;
    DateTime now = DateTime.now();
    DateTime fechaFutura = now.add(Duration(days: 30));
    String fecha =
        "${fechaFutura.year}-${fechaFutura.month.toString().padLeft(2, '0')}-${fechaFutura.day.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Finalizar Venta"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DropdownButtonFormField<String>(
                            value: clienteSeleccionado,
                            hint: Text("Seleccione un cliente"),
                            items: clientes.map((cliente) {
                              return DropdownMenuItem<String>(
                                value: cliente['id'].toString(),
                                child: Text(cliente['nombre']),
                              );
                            }).toList(),
                            onChanged: (nuevoValor) {
                              setState(() {
                                if (nuevoValor != null) {
                                  idCliente = int.tryParse(nuevoValor);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          _showInputDialog(context);
                          List<Map<String, dynamic>> nuevaLista =
                              await dbHelper.getClientes();
                          setState(() {
                            clientes = nuevaLista;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total a pagar:"),
                      Text("\$${totalPagar.toStringAsFixed(2)}"),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: montoPagadoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Monto abonado por el cliente",
                    ),
                    onChanged: (valor) {
                      setState(() {
                        montoAbonado = double.tryParse(valor) ?? 0.0;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Monto faltante:"),
                      Text(
                        "\$${_calcularMontoapartar(totalPagar).toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Fecha máxima de pago:  "),
                      Text(
                        "$fecha",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "             Recuerda que, después de pasar \n                  la fecha máxima de pago, \nla orden se cancelara y no habrá devoluciones.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    idCliente = null;
                    montoPagadoController.clear();
                  },
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    if (idCliente == null ||
                        montoAbonado == null ||
                        montoAbonado! <= 0 ||
                        totalPagar <= montoAbonado!) {
                      if (totalPagar <= montoAbonado!) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Pedido cancelado, el monto bonado es superior al total a pagar')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Por favor, complete todos los campos')),
                        );
                      }
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Pedido realizado exitosamente')),
                      );

                      Map<String, dynamic>? productoActuExis;

                      for (var producto in productosBuscados) {
                        productosBuscadosEnviar.add({
                          'producto_id': producto['id'],
                          'cantidad': producto['productos_comprados'],
                          'precio_unitario': producto['precio_venta'],
                          'descripcion': producto['descripcion'],
                        });

                        productoActuExis =
                            await dbHelper.getProductoById(producto['id']);
                        int existenciasActuales =
                            productoActuExis?['existencia'];
                        int pro_comp = producto['productos_comprados'];
                        int nuevasExistencias = existenciasActuales - pro_comp;
                        await dbHelper.updateProducto(
                            producto['id'], {'existencia': nuevasExistencias});
                      }

                      dbHelper.crearOrden(
                        idCliente!,
                        montoAbonado!.toInt(),
                        totalPagar.toInt(),
                        'pendiente',
                        productosBuscadosEnviar,
                      );

                      confirmarYLimpiarTabla();

                      idCliente = null;
                      montoPagadoController.clear();
                    }
                  },
                  child: Text("Finalizar Compra"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calcularMontoDevolver(double totalPagar) {
    double montoPagado = double.tryParse(montoPagadoController.text) ?? 0.0;
    return montoPagado - totalPagar;
  }

  double _calcularMontoapartar(double totalPagar) {
    final montoAbonado = double.tryParse(montoPagadoController.text) ?? 0.0;
    double falta = totalPagar - montoAbonado;
    return falta;
  }

  void buscarProducto() async {
    String codigo = codigoBarrasController.text;
    List<Map<String, dynamic>> resultados =
        await dbHelper.getProductoCoBa(codigo);

    setState(() {
      for (var producto in resultados) {
        bool existe = productosBuscados
            .any((p) => p['codigo_barras'] == producto['codigo_barras']);
        if (!existe) {
          var productoModificable = Map<String, dynamic>.from(producto);
          productoModificable['productos_comprados'] = 1;
          productosBuscados.add(productoModificable);
        }
        _actualizarPaginacion();
      }
    });
  }

  void incrementarCantidad(Map<String, dynamic> producto) {
    setState(() {
      producto['productos_comprados'] += 1;
    });
  }

  void decrementarCantidad(Map<String, dynamic> producto) {
    setState(() {
      if (producto['productos_comprados'] > 1) {
        producto['productos_comprados'] -= 1;
      }
    });
  }

  void editarProducto(Map<String, dynamic> producto) {
    TextEditingController descripcionController =
        TextEditingController(text: producto['descripcion']);
    TextEditingController precioVentaController =
        TextEditingController(text: producto['precio_venta'].toString());
    TextEditingController cantidadController =
        TextEditingController(text: producto['productos_comprados'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar Producto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: precioVentaController,
                decoration: InputDecoration(labelText: 'Precio Venta'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cantidadController,
                decoration: InputDecoration(labelText: 'Productos Comprados'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  producto['descripcion'] = descripcionController.text;
                  producto['precio_venta'] =
                      double.tryParse(precioVentaController.text) ??
                          producto['precio_venta'];
                  producto['productos_comprados'] =
                      int.tryParse(cantidadController.text) ??
                          producto['productos_comprados'];
                });
                Navigator.of(context).pop();
              },
              child: Text("Guardar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  void eliminarProducto(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmar Eliminación"),
          content: Text("¿Deseas eliminar este producto?"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  productosPaginados.remove(producto);
                  productosBuscados.remove(producto);
                });
                Navigator.of(context).pop();
              },
              child: Text("Sí"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }

  void limpiarTabla() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmar Eliminación"),
          content: Text("¿Deseas cancelar la compra?"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  productosPaginados.clear();
                  productosBuscados.clear();
                  productosBuscadosEnviar.clear();
                });
                Navigator.of(context).pop();
              },
              child: Text("Sí"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }

  void confirmarYLimpiarTabla() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pedido realizado exitosamente"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  productosPaginados.clear();
                  productosBuscados.clear();
                  productosBuscadosEnviar.clear();
                });
                Navigator.of(context).pop();
              },
              child: Text("Okey"),
            ),
          ],
        );
      },
    );
  }

  void mostrarOpcionesCompra() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Opciones de Compra"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Cancelar Compra"),
                onTap: () {
                  Navigator.of(context).pop();

                  limpiarTabla();
                },
              ),
              ListTile(
                title: Text("Pagar Producto"),
                onTap: () {
                  Navigator.of(context).pop();
                  mostrarMenuPago(productosBuscados);
                },
              ),
              ListTile(
                title: Text("Apartar Productos"),
                onTap: () {
                  Navigator.of(context).pop();
                  mostrarMenuapartar(productosBuscados);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            buildProfileImage(),
            const SizedBox(width: 10),
            Text('Venta'),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      drawer: buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: buscarProducto,
                ),
                Expanded(
                  child: TextField(
                    controller: codigoBarrasController,
                    decoration: InputDecoration(
                      labelText: "Código de Barras",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 35),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: const Color.fromARGB(255, 53, 52, 52)),
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
                    columns: [
                      DataColumn(label: Text('Código Barras')),
                      DataColumn(label: Text('Descripción')),
                      DataColumn(label: Text('Precio Venta')),
                      DataColumn(label: Text('Productos Comprados')),
                      DataColumn(label: Text('Opciones')),
                    ],
                    rows: productosPaginados.map((producto) {
                      return DataRow(cells: [
                        DataCell(Text(producto['codigo_barras'].toString())),
                        DataCell(Text(producto['descripcion'])),
                        DataCell(Text(producto['precio_venta'].toString())),
                        DataCell(
                            Text(producto['productos_comprados'].toString())),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => editarProducto(producto),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => eliminarProducto(producto),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_shopping_cart),
                              onPressed: () => incrementarCantidad(producto),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_shopping_cart),
                              onPressed: () => decrementarCantidad(producto),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _retrocederPagina,
                child: Text('Anterior'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _avanzarPagina,
                child: Text('Siguiente'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Paginación : '),
              DropdownButton<int>(
                value: productosPorPagina,
                items: List.generate(20, (index) => index + 1)
                    .map((cantidad) => DropdownMenuItem(
                          value: cantidad,
                          child: Text('$cantidad '),
                        ))
                    .toList(),
                onChanged: (cantidad) => _cambiarProductosPorPagina(cantidad!),
              ),
              Text('  Página ${paginaActual + 1} de $totalPaginas '),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarOpcionesCompra,
        child: const Icon(Icons.attach_money),
        backgroundColor: primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
