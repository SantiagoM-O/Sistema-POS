// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:pos/main.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  Color selectedColor = primaryColor;

  void seleccionarColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                  primaryColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                await savePrimaryColor(primaryColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void seleccionarColorBasico(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                  primaryColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                await savePrimaryColor(primaryColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void opcionesColores(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Opciones de Compra"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Color predeterminado"),
                onTap: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    primaryColor = const Color.fromARGB(255, 58, 72, 196);
                    selectedColor = const Color.fromARGB(255, 58, 72, 196);
                  });
                  await savePrimaryColor(primaryColor);
                },
              ),
              ListTile(
                title: Text("Colores básicos"),
                onTap: () {
                  Navigator.of(context).pop();
                  seleccionarColorBasico(context);
                },
              ),
              ListTile(
                title: Text("Seleccionar Color"),
                onTap: () {
                  Navigator.of(context).pop();
                  seleccionarColor(context);
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

  Future<File?> pickBackgroundImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_image_path', image.path);

      ImageProcessor processor = ImageProcessor();
      processor.processImage(image);

      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  Future<File?> pickLogoImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_logo_image_path', image.path);

      ImageProcessor processor = ImageProcessor();
      processor.processLogoImage(image);

      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  void _showInputDialog(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('-   Ingresar el nombre    -'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Nombre', nombreController, TextInputType.text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (nombreController.text.isEmpty) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    nombreLocal = nombreController.text;
                  });
                  await saveNombre(nombreLocal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre guardado con exito')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            buildProfileImage(),
            const SizedBox(width: 10),
            Text('Ajustes'),
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
                    if (section['text'] == 'cambiar logo') {
                      await pickLogoImage();
                      setState(() {});
                    }
                    if (section['text'] == 'cambiar background') {
                      await pickBackgroundImage();
                      setState(() {});
                    }
                    if (section['text'] == 'cambiar nombre') {
                      _showInputDialog(context);
                    }
                    if (section['text'] == 'cambiar color') {
                      opcionesColores(context);
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

final List<Map<String, dynamic>> sectionsHome = [
  {
    'icon': Icons.account_circle,
    'text': 'cambiar logo',
  },
  {
    'icon': Icons.add_to_queue,
    'text': 'cambiar background',
  },
  {
    'icon': Icons.abc,
    'text': 'cambiar nombre',
  },
  {
    'icon': Icons.animation_outlined,
    'text': 'cambiar color',
  },
];
