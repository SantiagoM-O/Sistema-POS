import 'package:flutter/material.dart';
import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';

class InformesPage extends StatefulWidget {
  @override
  _InformesPageState createState() => _InformesPageState();
}

class _InformesPageState extends State<InformesPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  bool mostrarOrdenes = false;
  bool mostrarEstadisticas = false;

  List<Map<String, dynamic>> ordenes = [];
  Map<int, List<Map<String, dynamic>>> productosPorOrden = {};
  Map<int, Map<String, dynamic>> clientes = {};

  String clienteMasComprador = '';
  List<Map<String, dynamic>> productosClienteMasComprador = [];
  double totalGastadoCliente = 0.0;
  List<Map<String, dynamic>> productosMasVendidos = [];
  List<Map<String, dynamic>> productosMenosVendidos = [];
  List<Map<String, dynamic>> mejoresClientes = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final ordenesData = await dbHelper.getOrdenes();
    Map<int, List<Map<String, dynamic>>> productosData = {};
    Map<int, Map<String, dynamic>> clientesData = {};

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

    final clienteMasCompradorData = await dbHelper.getClienteMasComprador();
    final productosMasVendidosData = await dbHelper.getProductosMasVendidos(3);
    final productosMenosVendidosData =
        await dbHelper.getProductosMenosVendidos(3);
    final mejoresClientesData = await dbHelper.getMejoresClientes(5);

    final clienteIdMasComprador = clienteMasCompradorData?['id'];
    if (clienteIdMasComprador != null) {
      final productosComprados =
          await dbHelper.getProductosCompradosPorCliente(clienteIdMasComprador);
      totalGastadoCliente = productosComprados.fold(
          0.0,
          (sum, producto) =>
              sum + (producto['cantidad'] * producto['precio_unitario']));
      setState(() {
        productosClienteMasComprador = productosComprados;
      });
    }

    setState(() {
      ordenes = ordenesData;
      productosPorOrden = productosData;
      clientes = clientesData;
      clienteMasComprador = clienteMasCompradorData?['nombre'] ?? 'Desconocido';
      productosMasVendidos = productosMasVendidosData;
      productosMenosVendidos = productosMenosVendidosData;
      mejoresClientes = mejoresClientesData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        backgroundColor: primaryColor,
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                mostrarOrdenes = !mostrarOrdenes;
                mostrarEstadisticas = false;
              });
            },
            child: const Text('Órdenes'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                mostrarEstadisticas = !mostrarEstadisticas;
                mostrarOrdenes = false;
              });
            },
            child: const Text('Estadísticas'),
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: mostrarOrdenes
          ? _buildOrdenesList()
          : mostrarEstadisticas
              ? _buildEstadisticas()
              : Center(
                  child: Text(
                    'Presiona un botón para ver los datos',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
    );
  }

  Widget _buildOrdenesList() {
    return ListView.builder(
      itemCount: ordenes.length,
      itemBuilder: (context, index) {
        final orden = ordenes[index];
        final clienteId = orden['cliente_id'];
        final cliente = clientes[clienteId];
        final productos = productosPorOrden[orden['id']] ?? [];

        return Card(
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(
                "Orden #${orden['id']} - Cliente: ${cliente?['nombre'] ?? 'Desconocido'}"),
            subtitle:
                Text("Fecha: ${orden['fecha']} - Estado: ${orden['estado']}"),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Cantidad')),
                    DataColumn(label: Text('Precio')),
                  ],
                  rows: productos.map((producto) {
                    return DataRow(cells: [
                      DataCell(Text(producto['producto_id'].toString())),
                      DataCell(Text(producto['descripcion'].toString())),
                      DataCell(Text(producto['cantidad'].toString())),
                      DataCell(Text("\$${producto['precio_unitario']}")),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    return ListView(
      padding: EdgeInsets.all(8.0),
      children: [
        Card(
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text('Cliente que más compró: $clienteMasComprador'),
            subtitle: Text(
                'Total gastado: \$${totalGastadoCliente.toStringAsFixed(2)}'),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Cantidad')),
                    DataColumn(label: Text('Precio Unitario')),
                  ],
                  rows: productosClienteMasComprador.map((producto) {
                    return DataRow(cells: [
                      DataCell(Text(producto['producto_id'].toString())),
                      DataCell(Text(producto['descripcion'].toString())),
                      DataCell(Text(producto['cantidad'].toString())),
                      DataCell(Text("\$${producto['precio_unitario']}")),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text('Mejores Clientes'),
            children: mejoresClientes.map((cliente) {
              return ListTile(
                title: Text(cliente['nombre']),
                subtitle: Text(
                    'Total gastado: \$${cliente['total_gastado'].toStringAsFixed(2)}'),
              );
            }).toList(),
          ),
        ),
        Card(
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text('Productos más vendidos'),
            children: productosMasVendidos.map((producto) {
              return ListTile(
                title: Text(producto['descripcion']),
                subtitle:
                    Text('Cantidad vendida: ${producto['cantidad_vendida']}'),
              );
            }).toList(),
          ),
        ),
        Card(
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text('Productos menos vendidos'),
            children: productosMenosVendidos.map((producto) {
              return ListTile(
                title: Text(producto['descripcion']),
                subtitle:
                    Text('Cantidad vendida: ${producto['cantidad_vendida']}'),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
