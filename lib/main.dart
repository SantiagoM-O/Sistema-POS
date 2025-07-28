import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/src/inventario.dart';
import 'package:pos/src/venta.dart';
import 'package:pos/src/clientes.dart';
import 'package:pos/src/informes.dart';
import 'package:pos/src/facturas.dart';
import 'package:pos/src/abonar.dart';
import 'package:pos/src/ajustes.dart';
import 'package:pos/src/graficas.dart';

const Color defaultPrimaryColor = const Color.fromARGB(255, 58, 72, 196);
Color primaryColor = defaultPrimaryColor;
String nombreLocal = 'Mi local';

File? _image;
File? _imagenLogo;

class ImageProcessor {
  void processImage(File image) {
    _image = image;
  }

  void processLogoImage(File image) {
    _imagenLogo = image;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el soporte FFI para sqflite solo si esta en escritorio:
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await loadPrimaryColor();
  loadLogoImage();
  loadBackgroundImage();
  await loadNombre();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Sistema de ventas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            buildProfileImage(),
            const SizedBox(width: 10),
            Text(widget.title),
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
                ? 4
                : constraints.maxWidth > 600
                    ? 3
                    : constraints.maxWidth > 300
                        ? 2
                        : 1;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1,
              children: sectionsHome.map((section) {
                return SectionButton(
                  icon: section['icon'],
                  text: section['text'],
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => section['page']),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> sectionsHome = [
  {
    'icon': Icons.inventory,
    'text': 'Inventario',
    'page': const InventarioPage(),
  },
  {
    'icon': Icons.point_of_sale,
    'text': 'Venta',
    'page': VentaPage(),
  },
  {
    'icon': Icons.add_card,
    'text': 'Abonar',
    'page': AbonarPage(),
  },
  //{
  //  'icon': Icons.all_inbox,
  //  'text': 'Caja',
  //  'page': const MyHomePage(title: 'Sistema de ventas'),
  //},
  {
    'icon': Icons.people_alt,
    'text': 'Clientes',
    'page': const ClientePage(),
  },
  {
    'icon': Icons.receipt_long,
    'text': 'Facturas',
    'page': ReciboPage(),
  },
  {
    'icon': Icons.insert_drive_file,
    'text': 'Informes',
    'page': InformesPage(),
  },
  {
    'icon': Icons.show_chart,
    'text': 'Gráficas',
    'page': EstadisticasScreen(),
  },
  {
    'icon': Icons.settings,
    'text': 'Ajustes',
    'page': AjustesPage(),
  },
];

final List<Map<String, dynamic>> sectionsDrawer = [
  {
    'icon': Icons.home,
    'text': 'Inicio',
    'page': const MyHomePage(title: 'Sistema de ventas'),
  },
  {
    'icon': Icons.inventory,
    'text': 'Inventario',
    'page': const InventarioPage(),
  },
  {
    'icon': Icons.point_of_sale,
    'text': 'Venta',
    'page': VentaPage(),
  },
  {
    'icon': Icons.people_alt,
    'text': 'Clientes',
    'page': const ClientePage(),
  },
  //{
  //  'icon': Icons.all_inbox,
  //  'text': 'Caja',
  //  'page': const MyHomePage(title: 'Sistema de ventas'),
  //},
  {
    'icon': Icons.insert_drive_file,
    'text': 'Reportes',
    'page': InformesPage(),
  },
  {
    'icon': Icons.settings,
    'text': 'Ajustes',
    'page': AjustesPage(),
  },
];

Future<void> savePrimaryColor(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('primaryColor', color.value);
}

Future<void> loadPrimaryColor() async {
  final prefs = await SharedPreferences.getInstance();
  int? colorValue = prefs.getInt('primaryColor');
  if (colorValue != null) {
    primaryColor = Color(colorValue);
  }
}

Future<File?> loadBackgroundImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? imagePath = prefs.getString('saved_image_path');
  if (imagePath != null) {
    _image = File(imagePath);
    return File(imagePath);
  } else {
    return null;
  }
}

Future<File?> loadLogoImage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? logoImagePath = prefs.getString('saved_logo_image_path');
  if (logoImagePath != null) {
    _imagenLogo = File(logoImagePath);
    return File(logoImagePath);
  } else {
    return null;
  }
}

Widget buildProfileImage() {
  if (_imagenLogo != null) {
    return CircleAvatar(
      radius: 20,
      backgroundImage: FileImage(_imagenLogo!),
    );
  } else {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    );
  }
}

Future<void> saveNombre(String nombre) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('nombreLocal', nombre);
}

Future<void> loadNombre() async {
  final prefs = await SharedPreferences.getInstance();
  String? nombre = prefs.getString('nombreLocal');
  if (nombre != null) {
    nombreLocal = nombre;
  }
}

Drawer buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: primaryColor,
            image: _image != null
                ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: const Text(
            '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        Center(
          child: Text(
            nombreLocal,
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            ),
          ),
        ),
        ...sectionsDrawer.map((section) {
          return ListTile(
            leading: Icon(section['icon']),
            title: Text(section['text']),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => section['page']),
              );
            },
          );
        }).toList(),
      ],
    ),
  );
}

class SectionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const SectionButton(
      {super.key,
      required this.icon,
      required this.text,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: primaryColor),
            const SizedBox(height: 8.0),
            Text(
              text,
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
