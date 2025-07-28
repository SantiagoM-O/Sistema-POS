import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos/src/dasebate.dart';
import 'package:pos/main.dart';

class EstadisticasScreen extends StatefulWidget {
  @override
  _EstadisticasScreenState createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final dbHelper = DatabaseHelper();
  List<BarChartGroupData> productosMasVendidoData = [];
  List<Map<String, dynamic>> productosMasVendido = [];
  List<BarChartGroupData> clientesValorComprasData = [];

  List<BarChartGroupData> clientesProductosCompradosData = [];

  @override
  void initState() {
    super.initState();
    cargarDatosGraficos();
  }

  List<ClienteValor> clientesValorCompras = [];

  Future<void> cargarDatosGraficos() async {
    productosMasVendido = await dbHelper.getProductosMasVendido();

    var clientesConMasCompras = await dbHelper.getClientesConMasCompras();
    clientesValorComprasData =
        clientesConMasCompras.asMap().entries.map((entry) {
      int index = entry.key;
      var cliente = entry.value;

      clientesValorCompras.add(ClienteValor(cliente['id'], cliente['nombre'],
          cliente['total_precio'], cliente['cantidad_productos']));

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cliente['total_precio'].toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    var clientesPorProductosComprados =
        await dbHelper.getClientesOrdenadosPorProductosComprados();
    clientesProductosCompradosData =
        clientesPorProductosComprados.asMap().entries.map((entry) {
      int index = entry.key;
      var cliente = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cliente['cantidad_productos'].toDouble(),
            color: Colors.orange,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    setState(() {
      productosMasVendidoData =
          productosMasVendido.asMap().entries.map((entry) {
        int index = entry.key;
        var producto = entry.value;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: producto['total_vendido'].toDouble(),
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList();
    });
  }

  void _showProductoMasVendido(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.8,
            child: BarChart(_buildProductoMasVendidoChart()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showClientesValorCompras(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.6,
            child: BarChart(_buildClientesValorComprasChart()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showClientesProductosComprados(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.6,
            child: BarChart(_buildClientesProductosCompradosChart()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
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
            Text('Estadísticas'),
          ],
        ),
        backgroundColor: primaryColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200
                ? 5
                : constraints.maxWidth > 800
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1,
              children: sectionsHome.map((section) {
                return SectionButton(
                  icon: section['icon'],
                  text: section['text'],
                  onPressed: () async {
                    if (section['text'] == 'Productos Más Vendidos') {
                      _showProductoMasVendido(context, section['text']);
                    }
                    if (section['text'] ==
                        '       Clientes Con \nMás Valor Comprado') {
                      _showClientesValorCompras(context, section['text']);
                    }
                    if (section['text'] ==
                        '            Clientes Con \nMás Productos Comprados') {
                      _showClientesProductosComprados(context, section['text']);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

BarChartData _buildProductoMasVendidoChart() {
  return BarChartData(
    barGroups: productosMasVendidoData,
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        axisNameWidget: Text("Ventas"),
        sideTitles: SideTitles(
          getTitlesWidget: (value, meta) {
            return Text(value.toString());
          },
          reservedSize: 50,
        ),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: Text("Productos"),
        sideTitles: SideTitles(
          getTitlesWidget: (value, meta) {
            if (value.toInt() < productosMasVendidoData.length) {
              return Text(productosMasVendidoData[value.toInt()]
                  .barRods[0]
                  .toY
                  .toString());
            }
            return Text('');
          },
          reservedSize: 40,
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles()),
      rightTitles: AxisTitles(sideTitles: SideTitles()),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border.all(color: const Color(0xff37434d), width: 1),
    ),
    gridData: FlGridData(show: true),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        direction: TooltipDirection.bottom,
        getTooltipColor: (group) => Colors.blueAccent,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final barRod = productosMasVendidoData[groupIndex].barRods[rodIndex];
          final totalPrecio = productosMasVendido[groupIndex]['total_precio'];

          final productName = 'Producto ${groupIndex + 1}';
          final sales = barRod.toY.toString();

          return BarTooltipItem(
            '$productName\nVentas: $sales\nTotal Precio: \$${totalPrecio.toStringAsFixed(2)}',
            TextStyle(color: Colors.white),
          );
        },
      ),
    ),
  );
}

  BarChartData _buildClientesValorComprasChart() {
    return BarChartData(
      barGroups: clientesValorComprasData,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Text("Total Comprado"),
          sideTitles: SideTitles(
            getTitlesWidget: (value, meta) {
              return Text(value.toString());
            },
            reservedSize: 50,
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text("Clientes"),
          sideTitles: SideTitles(
            getTitlesWidget: (value, meta) {
              if (value.toInt() < clientesValorComprasData.length) {
                return Text(clientesValorComprasData[value.toInt()]
                    .barRods[0]
                    .toY
                    .toString());
              }
              return Text('');
            },
            reservedSize: 40,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles()),
        rightTitles: AxisTitles(sideTitles: SideTitles()),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      gridData: FlGridData(show: true),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.greenAccent,
          direction: TooltipDirection.bottom,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final barRod =
                clientesValorComprasData[groupIndex].barRods[rodIndex];

            ClienteValor cliente = clientesValorCompras[groupIndex];

            String clientId = cliente.id.toString();
            String clientName = cliente.nombre;
            String productCount = cliente.cantidad_productos.toString();
            String totalSpent = barRod.toY.toString();

            return BarTooltipItem(
                'ID: $clientId\nNombre: \n$clientName\nCantidad: $productCount\nValor: \$${totalSpent}',
                TextStyle(color: Colors.white));
          },
        ),
      ),
    );
  }

  BarChartData _buildClientesProductosCompradosChart() {
    return BarChartData(
      barGroups: clientesProductosCompradosData,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Text("Cantidad"),
          sideTitles: SideTitles(
            getTitlesWidget: (value, meta) {
              return Text(value.toString());
            },
            reservedSize: 50,
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text("Clientes"),
          sideTitles: SideTitles(
            getTitlesWidget: (value, meta) {
              if (value.toInt() < clientesProductosCompradosData.length) {
                return Text(clientesProductosCompradosData[value.toInt()]
                    .barRods[0]
                    .toY
                    .toString());
              }
              return Text('');
            },
            reservedSize: 40,
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles()),
        rightTitles: AxisTitles(sideTitles: SideTitles()),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      gridData: FlGridData(show: true),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.orangeAccent,
          direction: TooltipDirection.bottom,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final barRod =
                clientesProductosCompradosData[groupIndex].barRods[rodIndex];

            ClienteValor cliente = clientesValorCompras[groupIndex];

            String clientId = cliente.id.toString();
            String clientName = cliente.nombre;
            String productCount = barRod.toY.toString();

            return BarTooltipItem(
                'ID: $clientId\nNombre: \n$clientName\nCantidad: $productCount',
                TextStyle(color: Colors.white));
          },
        ),
      ),
    );
  }
}

class ClienteValor {
  final int id;
  final String nombre;
  final double totalPrecio;
  final int cantidad_productos;

  ClienteValor(this.id, this.nombre, this.totalPrecio, this.cantidad_productos);
}

final List<Map<String, dynamic>> sectionsHome = [
  {
    'icon': Icons.align_vertical_bottom_rounded,
    'text': 'Productos Más Vendidos',
  },
  {
    'icon': Icons.align_vertical_bottom,
    'text': '       Clientes Con \nMás Valor Comprado',
  },
  {
    'icon': Icons.align_vertical_center_rounded,
    'text': '            Clientes Con \nMás Productos Comprados',
  },
];
