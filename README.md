---

# Sistema POS - Flutter

Este proyecto es una aplicación de Punto de Venta (POS) desarrollada con Flutter, diseñada para ser multiplataforma (Windows, Linux, Android, iOS). El objetivo es ofrecer una solución moderna, intuitiva y personalizable para la gestión de ventas, inventario y clientes en pequeños negocios.

## Características principales

- **Inventario:** Administra productos, cantidades y precios.
- **Ventas:** Realiza ventas rápidas y registra transacciones.
- **Clientes:** Gestiona información de clientes y su historial de compras.
- **Facturas y Abonos:** Genera facturas y permite registrar pagos parciales.
- **Informes:** Visualiza reportes de ventas, inventario y clientes.
- **Gráficas:** Analiza el rendimiento del negocio con estadísticas visuales.
- **Ajustes:** Personaliza el color principal, el logo y el fondo del menú lateral.
- **Interfaz adaptable:** El menú principal muestra las secciones en un grid que se ajusta automáticamente al tamaño de pantalla.
- **Drawer personalizado:** Acceso rápido a las principales secciones desde el menú lateral, con fondo y logo configurables.
- **Persistencia local:** Utiliza SQLite (`sqflite` y `sqflite_common_ffi`) para almacenar datos y `shared_preferences` para configuraciones.
- **Soporte multiplataforma:** Funciona en escritorio y dispositivos móviles.

## Estructura del proyecto

- main.dart: Punto de entrada y pantalla principal. Define la navegación, el menú principal y el drawer.
- src: Contiene las pantallas de Inventario, Venta, Clientes, Informes, Facturas, Abonar, Ajustes y Gráficas.
- **Recursos configurables:** Permite cambiar el logo y el fondo del drawer, así como el color principal de la app.

## Instalación

1. Clona el repositorio:
   ```
   git clone https://github.com/SantiagoM-O/Sistema-POS.git
   ```
2. Instala las dependencias:
   ```
   flutter pub get
   ```
3. Ejecuta la aplicación:
   ```
   flutter run
   ```

## Requisitos

- Flutter 3.x o superior
- Para escritorio: Windows o Linux (con soporte FFI para SQLite)
- Para móvil: Android/iOS

## Personalización

- Cambia el color principal desde la sección de Ajustes.
- Sube tu logo y fondo para el menú lateral.
- Modifica las secciones visibles en el menú principal y el drawer.

## Licencia

Este proyecto está bajo la licencia MIT.

---
