// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';

class ReciboPage extends StatefulWidget {
  @override
  _ReciboPageState createState() => _ReciboPageState();
}

class _ReciboPageState extends State<ReciboPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  int ordenesPorPagina = 5;
  int paginaActual = 0;
  int totalPaginas = 1;
  List<Map<String, dynamic>> ordenes = [];
  List<Map<String, dynamic>> ordenesPaginadas = [];
  Map<int, Map<String, dynamic>> clientes = {};
  Map<int, List<Map<String, dynamic>>> productosPorOrden = {};

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final ordenesData = await dbHelper.getOrdenes();
    Map<int, Map<String, dynamic>> clientesData = {};
    Map<int, List<Map<String, dynamic>>> productosData = {};

    for (var orden in ordenesData) {
      int clienteId = orden['cliente_id'];
      int ordenId = orden['id'];

      if (!clientesData.containsKey(clienteId)) {
        final cliente = await dbHelper.getClienteById(clienteId);
        if (cliente != null) {
          clientesData[clienteId] = cliente;
        }
      }

      productosData[ordenId] = await dbHelper.getProductosDeOrden(ordenId);
    }

    setState(() {
      ordenes = ordenesData;
      clientes = clientesData;
      productosPorOrden = productosData;
      _actualizarPaginacion();
    });
  }

  void _actualizarPaginacion() {
    setState(() {
      totalPaginas = (ordenes.length / ordenesPorPagina).ceil();
      int inicio = paginaActual * ordenesPorPagina;
      int fin = inicio + ordenesPorPagina;
      ordenesPaginadas = ordenes.sublist(
        inicio,
        fin > ordenes.length ? ordenes.length : fin,
      );
    });
  }

  void _cambiarOrdenesPorPagina(int cantidad) {
    setState(() {
      ordenesPorPagina = cantidad;
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

  void mostrarRecibo(BuildContext context, Map<String, dynamic> orden) {
    final cliente = clientes[orden['cliente_id']];
    final productos = productosPorOrden[orden['id']] ?? [];

    double total = productos.fold<double>(
      0,
      (sum, item) => sum + (item['cantidad'] * item['precio_unitario']),
    );

    double pagado = (orden['pagado'] ?? 0).toDouble();
    double deuda = total - pagado;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Recibo - Orden #${orden['id']}"),
          content: SizedBox(
            height: 400.0,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cliente: ${cliente?['nombre'] ?? 'Desconocido'}",
                      style: TextStyle(fontSize: 18)),
                  Text("Fecha: ${orden['fecha']}",
                      style: TextStyle(fontSize: 16)),
                  Text("Estado: ${orden['estado']}",
                      style: TextStyle(fontSize: 16)),
                  Divider(),
                  Text("Productos:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ...productos.map((producto) {
                    return ListTile(
                      title: Text(producto['descripcion'],
                          style: TextStyle(fontSize: 16)),
                      subtitle: Text("Cantidad: ${producto['cantidad']}",
                          style: TextStyle(fontSize: 14)),
                      trailing: Text("\$${producto['precio_unitario']}",
                          style: TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  Divider(),
                  Text(
                    "Total: \$${total.toStringAsFixed(2)}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "Pagado: \$${pagado.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  Text(
                    "Deuda: \$${deuda.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: deuda > 0 ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
            Text('Informes de Órdenes'),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      drawer: buildDrawer(context),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: const Color.fromARGB(255, 53, 52, 52)),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
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
                      DataColumn(
                          label:
                              Text('ID Orden', style: TextStyle(fontSize: 16))),
                      DataColumn(
                          label: Text('Nombre del Cliente',
                              style: TextStyle(fontSize: 16))),
                      DataColumn(
                          label: Text('Estado de Orden',
                              style: TextStyle(fontSize: 16))),
                      DataColumn(label: Icon(Icons.print)),
                    ],
                    rows: ordenesPaginadas.map((orden) {
                      final clienteId = orden['cliente_id'];
                      final cliente = clientes[clienteId];
                      return DataRow(cells: [
                        DataCell(Text(orden['id'].toString(),
                            style: TextStyle(fontSize: 18))),
                        DataCell(Text(cliente?['nombre'] ?? 'Desconocido',
                            style: TextStyle(fontSize: 18))),
                        DataCell(Text(orden['estado'],
                            style: TextStyle(fontSize: 18))),
                        DataCell(IconButton(
                          icon: Icon(Icons.print),
                          onPressed: () {
                            mostrarRecibo(context, orden);
                          },
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
              Text('Órdenes por página: '),
              DropdownButton<int>(
                value: ordenesPorPagina,
                items: List.generate(20, (index) => index + 1)
                    .map((cantidad) => DropdownMenuItem(
                          value: cantidad,
                          child: Text('$cantidad '),
                        ))
                    .toList(),
                onChanged: (cantidad) => _cambiarOrdenesPorPagina(cantidad!),
              ),
              Text('  Página ${paginaActual + 1} de $totalPaginas '),
            ],
          ),
        ],
      ),
    );
  }
}
