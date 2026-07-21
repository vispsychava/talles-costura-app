import 'package:flutter/material.dart';
import '../models/pedido.dart';

class PantallaCardPedido extends StatelessWidget {
  final Pedido pedido;

  const PantallaCardPedido({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    // Si necesitas crear o usar un pedido por defecto dentro de la pantalla:
    final fechaMostrar = pedido.fechaPedido;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${pedido.id}'),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cliente: ${pedido.clienteNombre}'),
                Text('Teléfono: ${pedido.clienteTelefono}'),
                Text('Fecha Pedido: ${fechaMostrar.toString().substring(0, 10)}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}