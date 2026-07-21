import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import 'detalle_pedido_screen.dart';

class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final PedidoService _pedidoService = PedidoService();
  bool _procesando = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code.startsWith('tallercostura://pedido/')) {
        setState(() {
          _procesando = true;
        });

        // Detenemos la cámara temporalmente
        await _controller.stop();

        final Uri uri = Uri.parse(code);
        final codigoPedido = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

        if (codigoPedido != null && mounted) {
          final clienteNombreQr = uri.queryParameters['cliente'] ?? 'Cliente Desconocido';
          final fechaEntregaStr = uri.queryParameters['entrega'];

          DateTime? fechaEntregaQr;
          if (fechaEntregaStr != null) {
            fechaEntregaQr = DateTime.tryParse(fechaEntregaStr);
          }

          // 1. Buscamos en Supabase
          Pedido? pedido = await _pedidoService.obtenerPedidoPorId(codigoPedido);

          // 2. Fallback de emergencia por si no hay internet
          pedido ??= Pedido(
            id: codigoPedido,
            clienteNombre: clienteNombreQr,
            clienteTelefono: '',
            fechaEntrega: fechaEntregaQr,
            fechaPedido: DateTime.now(),
            prendas: [],
            estado: 'Escaneado',
          );

          if (mounted) {
            // Reemplazamos la pantalla del escáner por la del detalle del pedido
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DetallePedidoScreen(
                  pedido: pedido!,
                  onPedidoActualizado: (_) {},
                ),
              ),
            );
          }
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Pedido'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Cargando pedido...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}