import 'package:flutter/material.dart';

class Eliminar extends StatelessWidget {
  const Eliminar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Eliminar"), backgroundColor: Colors.red),
      body: Center(child: Text("Pantalla de eliminar")),
    );
  }
}
