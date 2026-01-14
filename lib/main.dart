import '/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'screens/clients/clients_form_screen.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/home_screen.dart';
import 'screens/movimientos/movimientos_form_screen.dart';
import 'screens/movimientos/movimientos_sceen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/clients': (context) => ClientsScreen(),
        '/clients/form': (context) => ClientsFormScreen(),
        '/movimientos': (context) => MovimientosScreen(),
        '/movimientos/form': (context) => MovimientosFormScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
